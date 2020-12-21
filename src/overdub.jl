using Cassette

Cassette.@context CounterCtx;

const ternops = (
    (:fma, Core.Intrinsics.fma_float, 2), # 2 flops per FMA instruction
)

const binops = (
    (:add, Core.Intrinsics.add_float, 1),
    (:sub, Core.Intrinsics.sub_float, 1),
    (:mul, Core.Intrinsics.mul_float, 1),
    (:div, Core.Intrinsics.div_float, 1),
)

const unops = (
    (:sqrt, Core.Intrinsics.sqrt_llvm, 1),
)

const ops = Iterators.flatten((ternops, binops, unops)) |> collect

const typs = (
    (Float32, :32),
    (Float64, :64),
)


@eval mutable struct Counter
    $((:($(Symbol(op[1], typ[2])) ::Int) for op in ops for typ in typs)...)
    Counter() = new($((0 for _ in 1:length(ops)*length(typs))...))
end

function gen_count(ops, suffix)
    body = Expr(:block)
    for (name, op) in ops
        fieldname = Symbol(name, suffix)
        e = quote
            if op == $op
                ctx.metadata.$fieldname += 1
                return
            end
        end
        push!(body.args, e)
    end
    body
end

for (typ, suffix) in typs
    @eval function Cassette.prehook(ctx::CounterCtx,
                                    op::Core.IntrinsicFunction,
                                    ::$typ,
                                    ::$typ,
                                    ::$typ)
        $(gen_count(ternops, suffix))
    end

    @eval function Cassette.prehook(ctx::CounterCtx,
                                    op::Core.IntrinsicFunction,
                                    ::$typ,
                                    ::$typ)
        $(gen_count(binops, suffix))
    end

    @eval function Cassette.prehook(ctx::CounterCtx,
                                    op::Core.IntrinsicFunction,
                                    ::$typ)
        $(gen_count(unops, suffix))
    end
end


# Relatively inefficient, but there should be no need for performance here...

function flop(c::Counter)
    total = 0
    for (typ, suffix) in typs
        for (name, op, cnt) in ops
            fieldname = Symbol(name, suffix)
            total += cnt * getfield(c, fieldname)
        end
    end
    total
end

import Base: ==, *, show

function Base.show(io::IO, c::Counter)
    println(io, "Flop Counter:")
    type_names  = [typ    for (typ, _)    in typs]
    type_suffix = [suffix for (_, suffix) in typs]
    op_names    = [name   for (name, _)   in ops]

    mat = [getfield(c, Symbol(name, suffix)) for
           name   in op_names,
           suffix in type_suffix]
    pretty_table(io, mat, type_names,
                 row_names = op_names)
end

function ==(c1::Counter, c2::Counter)
    all(getfield(c1, field)==getfield(c2, field) for field in fieldnames(Counter))
end

function *(n::Int, c::Counter)
    ret = Counter()
    for field in fieldnames(Counter)
        setfield!(ret, field, n*getfield(c, field))
    end
    ret
end

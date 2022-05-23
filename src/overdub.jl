using Cassette

Cassette.@context CounterCtx;

const ternops = (
    (:fma, Core.Intrinsics.fma_float, 2), # 2 flops per FMA instruction
    (:muladd, Core.Intrinsics.muladd_float, 2), # 2 flops per muladd instruction
)

const binops = (
    (:add, Core.Intrinsics.add_float, 1),
    (:sub, Core.Intrinsics.sub_float, 1),
    (:mul, Core.Intrinsics.mul_float, 1),
    (:div, Core.Intrinsics.div_float, 1),
    (:rem, Core.Intrinsics.rem_float, 1),
)

const unops = (
    (:abs, Core.Intrinsics.abs_float, 1),
    (:neg, Core.Intrinsics.neg_float, 1),
    (:sqrt, Core.Intrinsics.sqrt_llvm, 1),
)

const ops = Iterators.flatten((ternops, binops, unops)) |> collect

const typs = (
    (Float16, :16),
    (Float32, :32),
    (Float64, :64),
)


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

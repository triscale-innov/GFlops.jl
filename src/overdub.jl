using Cassette

Cassette.@context CounterCtx;

const triops = (
    (:fma32, Core.Intrinsics.fma_float, Float32),
    (:muladd32, Core.Intrinsics.muladd_float, Float32),
    #
    (:fma64, Core.Intrinsics.fma_float, Float64),
    (:muladd64, Core.Intrinsics.muladd_float, Float64),
)

const binops = (
    (:abs32, Core.Intrinsics.abs_float, Float32),
    (:add32, Core.Intrinsics.add_float, Float32),
    (:ceil32, Core.Intrinsics.ceil_llvm, Float32),
    (:div32, Core.Intrinsics.div_float, Float32),
    (:floor32, Core.Intrinsics.floor_llvm, Float32),
    (:mul32, Core.Intrinsics.mul_float, Float32),
    (:rem32, Core.Intrinsics.rem_float, Float32),
    (:sub32, Core.Intrinsics.sub_float, Float32),
    (:trunc32, Core.Intrinsics.trunc_llvm, Float32),
    #
    (:abs64, Core.Intrinsics.abs_float, Float64),
    (:add64, Core.Intrinsics.add_float, Float64),
    (:ceil64, Core.Intrinsics.ceil_llvm, Float64),
    (:div64, Core.Intrinsics.div_float, Float64),
    (:floor64, Core.Intrinsics.floor_llvm, Float64),
    (:mul64, Core.Intrinsics.mul_float, Float64),
    (:rem64, Core.Intrinsics.rem_float, Float64),
    (:sub64, Core.Intrinsics.sub_float, Float64),
    (:trunc64, Core.Intrinsics.trunc_llvm, Float64),
)

const unops = (
    (:sqrt32, Core.Intrinsics.sqrt_llvm, Float32),
    #
    (:sqrt64, Core.Intrinsics.sqrt_llvm, Float64),
)

const ops = Iterators.flatten((triops, binops, unops)) |> collect

@eval mutable struct Counter
    $((:($(op[1]) ::Int) for op in ops)...)
    Counter() = new($((0 for _ in 1:length(ops))...))
end

for typ1 in (Float32, Float64)
    @eval function Cassette.prehook(ctx::CounterCtx,
                                    op::Core.IntrinsicFunction,
                                    ::$typ1,
                                    ::$typ1)
        $(Expr(:block,
               (map(binops) do (name, op, typ2)
                  typ1 == typ2 || return :nothing
                  quote
                    if op == $op
                       ctx.metadata.$name += 1
                       return
                    end
                  end
                end)...))
    end

    @eval function Cassette.prehook(ctx::CounterCtx,
                                    op::Core.IntrinsicFunction,
                                    ::$typ1)
        $(Expr(:block,
               (map(unops) do (name, op, typ2)
                  typ1 == typ2 || return :nothing
                  quote
                    if op == $op
                       ctx.metadata.$name += 1
                       return
                    end
                  end
                end)...))
    end
end

flop(c::Counter) = sum(getfield(c, field) for field in fieldnames(Counter))

function Base.show(io::IO, c::Counter)
    println(io, "Flop Counter:")
    for field in fieldnames(Counter)
        println(io, " $field: $(getfield(c, field))")
    end
end

using Cassette

Cassette.@context CounterCtx;

const ops = (
    (:add32, Core.Intrinsics.add_float, Float32),
    (:sub32, Core.Intrinsics.sub_float, Float32),
    (:mul32, Core.Intrinsics.mul_float, Float32),
    (:div32, Core.Intrinsics.div_float, Float32),
    (:add64, Core.Intrinsics.add_float, Float64),
    (:sub64, Core.Intrinsics.sub_float, Float64),
    (:mul64, Core.Intrinsics.mul_float, Float64),
    (:div64, Core.Intrinsics.div_float, Float64),
)

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
               (map(ops) do (name, op, typ2)
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

using Cassette

Cassette.@context CounterCtx;

ops = [
    (:add32, +, Float32, Float32),
    (:sub32, -, Float32, Float32),
    (:mul32, *, Float32, Float32),
    (:div32, /, Float32, Float32),
    (:add64, +, Float64, Float64),
    (:sub64, -, Float64, Float64),
    (:mul64, *, Float64, Float64),
    (:div64, /, Float64, Float64),
]

@eval mutable struct Counter
    $((:($(op[1]) ::Int) for op in ops)...)
    Counter() = new($((0 for _ in 1:length(ops))...))
end

for (name, op, typ1, typ2) in ops
    @eval function Cassette.prehook(ctx::CounterCtx, op::typeof($op), a::$typ1, b::$typ2)
        ctx.metadata.$name +=1
    end
end

flop(c::Counter) = sum(getfield(c, field) for field in fieldnames(Counter))

function Base.show(io::IO, c::Counter)
    println(io, "Flop Counter:")
    for field in fieldnames(Counter)
        println(io, " $field: $(getfield(c, field))")
    end
end

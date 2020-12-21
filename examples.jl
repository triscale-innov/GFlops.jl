# These examples are included in README.jl

using GFlops
x = rand(1000);
@count_ops sum($x)
@gflops sum($x);



function mixed_dot(x, y)
    acc = 0.0
    @inbounds @simd for i in eachindex(x, y)
        acc += x[i] * y[i]
    end
    acc
end
x = rand(Float32, 1000); y = rand(Float32, 1000);
cnt = @count_ops mixed_dot($x, $y)
fieldnames(GFlops.Counter)
cnt.add64
@gflops mixed_dot($x, $y);



function fma_dot(x, y)
    acc = zero(eltype(x))
    @inbounds for i in eachindex(x, y)
        acc = fma(x[i], y[i], acc)
    end
    acc
end
x = rand(100); y = rand(100);
println("# 100 FMAs...")
cnt = @count_ops fma_dot($x, $y)
println("# ...but 200 FLOPs")
GFlops.flop(cnt)
@gflops fma_dot($x, $y);



using LinearAlgebra
@count_ops dot($x, $y)

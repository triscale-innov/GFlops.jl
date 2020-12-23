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



x = 0.5; coeffs = rand(10);
println("# 9 MulAdds but 18 flop")
cnt = @count_ops evalpoly($x, $coeffs)
@gflops evalpoly($x, $coeffs);



using LinearAlgebra
x = rand(1000);
@count_ops dot($x, $y)

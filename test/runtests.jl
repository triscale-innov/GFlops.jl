using GFlops
using Test


function my_axpy!(a, x, y)
    @inbounds @simd for i in eachindex(x)
        y[i] += a*x[i]
    end
end

using .GFlops

let
    N = 1000
    x = rand(N)
    y = rand(N)
    @gflops my_axpy!(1.5, $x, $y)
end

let N = 100
    x = rand(N,N)
    y = rand(N)
    @gflops \($x, $y)
end

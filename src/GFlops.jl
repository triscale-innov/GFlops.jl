module GFlops
import Statistics
using BenchmarkTools:   @benchmark
using InteractiveUtils: peakflops
using Printf:           @printf

export @gflops

include("float.jl")
include("gflops.jl")

end # module

module GFlops
import Statistics
import BenchmarkTools
using BenchmarkTools:   @benchmark
using InteractiveUtils: peakflops
using Printf:           @printf
using PrettyTables:     pretty_table

export @gflops, @count_ops

include("overdub.jl")
include("Counter.jl")
include("count_ops.jl")

end # module

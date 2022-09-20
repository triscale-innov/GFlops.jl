module GFlops
import Statistics
import BenchmarkTools
using Pkg
# https://discourse.julialang.org/t/how-to-find-out-the-version-of-a-package-from-its-module/37755

pkgversion(m::Module) =
    VersionNumber(Pkg.TOML.parsefile(joinpath(dirname(string(first(methods(m.eval)).file)), "..", "Project.toml"))["version"])

using BenchmarkTools:   @benchmark
using InteractiveUtils: peakflops
using Printf:           @printf
import PrettyTables
using PrettyTables:     pretty_table

export @gflops, @count_ops

include("overdub.jl")
include("Counter.jl")
include("count_ops.jl")

end # module

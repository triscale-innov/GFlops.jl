#!/bin/bash
#=
exec julia -O3 --color=yes -qi "${BASH_SOURCE[0]}"
=#

using Pkg
cd(@__DIR__)
Pkg.activate("..")

using Retest
@retest(@__DIR__)

# Local Variables:
# mode: julia
# End:

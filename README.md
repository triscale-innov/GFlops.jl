# GFlops.jl

<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) --> 
![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg) [![Build Status](https://travis-ci.org/triscale-innov/GFlops.jl.svg?branch=master)](https://travis-ci.org/triscale-innov/GFlops.jl) [![codecov.io](http://codecov.io/github/triscale-innov/GFlops.jl/coverage.svg?branch=master)](http://codecov.io/github/triscale-innov/GFlops.jl?branch=master)

When code performance is an issue, it is sometimes useful to get absolute
performance measurements in order to objectivise what is "slow" or
"fast". `GFlops.jl` provides a way to automatically count the number of
floating-point operations in a piece of code. When combined with the power of
`BenchmarkTools`, this allows for easy and absolute performance measurements.

## Example use

```julia
julia> using GFlops

julia> using LinearAlgebra

julia> x = rand(1000);

julia> @count_ops dot($x, $x)
2001

julia> @gflops dot($x, $x);
  16.17 GFlops,  34.84% peak  (2.00e+03 flop, 1.24e-07 s)
```


## Installation

This package is not (yet?) registered. You will have to specify its full URL in
order to `Pkg.add` it:

```julia
(v1.1) pkg> add https://github.com/triscale-innov/GFlops.jl.git
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
   Cloning git-repo `https://github.com/triscale-innov/GFlops.jl.git`
  Updating git-repo `https://github.com/triscale-innov/GFlops.jl.git`
 Resolving package versions...
 [...]
```

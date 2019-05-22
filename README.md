# GFlops.jl

<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) --> 
![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg) [![Build Status](https://travis-ci.org/triscale-innov/GFlops.jl.svg?branch=master)](https://travis-ci.org/triscale-innov/GFlops.jl) [![codecov.io](http://codecov.io/github/triscale-innov/GFlops.jl/coverage.svg?branch=master)](http://codecov.io/github/triscale-innov/GFlops.jl?branch=master)

When code performance is an issue, it is sometimes useful to get absolute
performance measurements in order to objectivise what is "slow" or
"fast". `GFlops.jl` leverages the power of `Cassette.jl` to automatically count
the number of floating-point operations in a piece of code. When combined with
the accuracy of `BenchmarkTools`, this allows for easy and absolute performance
measurements.

## Example use

```julia
julia> using GFlops

julia> x = rand(1000);

julia> @count_ops sum($x)
Flop Counter:
 add32: 0
 sub32: 0
 mul32: 0
 div32: 0
 add64: 999
 sub64: 0
 mul64: 0
 div64: 0


julia> @gflops sum($x);
  10.03 GFlops,  19.15% peak  (9.99e+02 flop, 9.96e-08 s)
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


## Caveat

`GFlops.jl` does not see what happens outside the realm of Julia code. It
especially does not see operations performed in external libraries such as BLAS
calls:
```julia
julia> using LinearAlgebra

julia> @count_ops dot($x, $x)
Flop Counter:
 add32: 0
 sub32: 0
 mul32: 0
 div32: 0
 add64: 0
 sub64: 0
 mul64: 0
 div64: 0
```

This is a known issue; we'll try and find a way to circumvent the problem.

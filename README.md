# GFlops.jl

<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg) -->
<!-- ![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) --> 
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
[![Build Status](https://github.com/triscale-innov/GFlops.jl/workflows/CI/badge.svg)](https://github.com/triscale-innov/GFlops.jl/actions)
[![Coverage](http://codecov.io/github/triscale-innov/GFlops.jl/coverage.svg?branch=master)](http://codecov.io/github/triscale-innov/GFlops.jl?branch=master)

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
┌──────┬─────────┬─────────┐
│      │ Float32 │ Float64 │
├──────┼─────────┼─────────┤
│  fma │       0 │       0 │
│  add │       0 │     999 │
│  sub │       0 │       0 │
│  mul │       0 │       0 │
│  div │       0 │       0 │
│ sqrt │       0 │       0 │
└──────┴─────────┴─────────┘

julia> @gflops sum($x);
  10.03 GFlops,  19.15% peak  (9.99e+02 flop, 9.96e-08 s, 0 alloc: 0 bytes)
```


## Installation

This package is registered and can therefore be simply be installed with

```julia
pkg> add GFlops
```


## Caveats

### FMA - Fused Multiplication and Addition

On systems which support them, FMAs compute two operations (an addition and a
multiplication) in one instruction. `@count_ops` counts each individual FMA as
one operation, which makes it easier to interpret counters. However, `@gflops`
(and the internal `GFlops.flops` function) will count two floating-point
operations for each FMA, in accordance to the way high-performance benchmarks
usually behave:

```julia
julia> function my_dot(x, y)
           acc = zero(eltype(x))
           @inbounds for i in eachindex(x, y)
               acc = fma(x[i], y[i], acc)
           end
           acc
       end
my_dot (generic function with 1 method)

julia> x = rand(100); y = rand(100);

# 100 FMAs...
julia> cnt = @count_ops my_dot(x, y)
Flop Counter:
┌──────┬─────────┬─────────┐
│      │ Float32 │ Float64 │
├──────┼─────────┼─────────┤
│  fma │       0 │     100 │
│  add │       0 │       0 │
│  sub │       0 │       0 │
│  mul │       0 │       0 │
│  div │       0 │       0 │
│ sqrt │       0 │       0 │
└──────┴─────────┴─────────┘

# ...but 200 FLOPs
julia> GFlops.flop(cnt)
200
```

### Non-julia code

`GFlops.jl` does not see what happens outside the realm of Julia code. It
especially does not see operations performed in external libraries such as BLAS
calls:
```julia
julia> using LinearAlgebra

julia> @count_ops dot($x, $x)
Flop Counter:
┌──────┬─────────┬─────────┐
│      │ Float32 │ Float64 │
├──────┼─────────┼─────────┤
│  fma │       0 │       0 │
│  add │       0 │       0 │
│  sub │       0 │       0 │
│  mul │       0 │       0 │
│  div │       0 │       0 │
│ sqrt │       0 │       0 │
└──────┴─────────┴─────────┘
```

This is a known issue; we'll try and find a way to circumvent the problem.

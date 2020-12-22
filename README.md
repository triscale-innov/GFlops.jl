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


## Installation

This package is registered and can therefore be simply be installed with

```julia
pkg> add GFlops
```


## Example use

This simple example shows how to track the number of operations in a vector summation:
```julia
julia> using GFlops

julia> x = rand(1000);

julia> @count_ops sum($x)
Flop Counter: 999 flop
┌─────┬─────────┐
│     │ Float64 │
├─────┼─────────┤
│ add │     999 │
└─────┴─────────┘

julia> @gflops sum($x);
  8.86 GFlops,  12.76% peak  (9.99e+02 flop, 1.13e-07 s, 0 alloc: 0 bytes)
```

<br/>

`GFlops.jl` internally tracks several types of Floating-Point operations, for
both 32-bit and 64-bit operands. Pretty-printing a Flop Counter only
shows non-zero entries, but any individual counter can be accessed:
```julia
julia> function mixed_dot(x, y)
           acc = 0.0
           @inbounds @simd for i in eachindex(x, y)
               acc += x[i] * y[i]
           end
           acc
       end
mixed_dot (generic function with 1 method)

julia> x = rand(Float32, 1000); y = rand(Float32, 1000);

julia> cnt = @count_ops mixed_dot($x, $y)
Flop Counter: 1000 flop
┌─────┬─────────┬─────────┐
│     │ Float32 │ Float64 │
├─────┼─────────┼─────────┤
│ add │       0 │    1000 │
│ mul │    1000 │       0 │
└─────┴─────────┴─────────┘

julia> fieldnames(GFlops.Counter)
(:fma32, :fma64, :add32, :add64, :sub32, :sub64, :mul32, :mul64, :div32, :div64, :sqrt32, :sqrt64)

julia> cnt.add64
1000

julia> @gflops mixed_dot($x, $y);
  9.91 GFlops,  13.36% peak  (2.00e+03 flop, 2.02e-07 s, 0 alloc: 0 bytes)
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
julia> function fma_dot(x, y)
           acc = zero(eltype(x))
           @inbounds for i in eachindex(x, y)
               acc = fma(x[i], y[i], acc)
           end
           acc
       end
fma_dot (generic function with 1 method)

julia> x = rand(100); y = rand(100);

# 100 FMAs but 200 flop
julia> cnt = @count_ops fma_dot($x, $y)
Flop Counter: 200 flop
┌─────┬─────────┐
│     │ Float64 │
├─────┼─────────┤
│ fma │     100 │
└─────┴─────────┘

julia> @gflops fma_dot($x, $y);
  1.58 GFlops,  2.12% peak  (2.00e+02 flop, 1.27e-07 s, 0 alloc: 0 bytes)
```

### Non-julia code

`GFlops.jl` does not see what happens outside the realm of Julia code. It
especially does not see operations performed in external libraries such as BLAS
calls:

```julia
julia> using LinearAlgebra

julia> @count_ops dot($x, $y)
Flop Counter: 0 flop
```

This is a known issue; we'll try and find a way to circumvent the problem.

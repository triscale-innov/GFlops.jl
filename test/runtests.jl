using GFlops
using Test

function my_axpy!(a, x, y)
    @inbounds @simd for i in eachindex(x)
        y[i] += a*x[i]
    end
end

function my_prod(m, v)
    res = similar(v, size(m, 1))

    for i in 1:size(m, 1)
        acc = zero(eltype(m))
        for j in 1:length(v)
            acc += m[i,j]*v[j]
        end
        res[i] = acc
    end
    res
end

import BenchmarkTools: @benchmark
struct FakeResults
    times
    allocs
    memory
end
macro benchmark(e)
    quote
        FakeResults(#= times  =# [2.0, 3.0],
                    #= allocs =# 1,
                    #= memory =# 1042)
    end
end


@testset "GFlops" begin
    @testset "Counter" begin
        let
            cnt = GFlops.Counter()
            iob = IOBuffer()
            show(iob, cnt)
            @test String(take!(iob)) == """
Flop Counter:
 fma32: 0
 fma64: 0
 add32: 0
 sub32: 0
 mul32: 0
 div32: 0
 add64: 0
 sub64: 0
 mul64: 0
 div64: 0
 sqrt32: 0
 sqrt64: 0
"""
        end
    end

    @testset "@count_ops" begin
        @testset "mul+add 64" begin
            let N = 100
                a = 2.5
                x = rand(N)
                y = similar(x)

                cnt = @count_ops my_axpy!(a, x, y)
                @test cnt.add64 == N
                @test cnt.mul64 == N
                @test GFlops.flop(cnt) == 2*N


                m = rand(N, N)
                v = rand(N)

                cnt = @count_ops(my_prod(m, v))
                @test cnt.add64 == N*N
                @test cnt.mul64 == N*N
                @test GFlops.flop(cnt) == 2*N*N
            end
        end

        @testset "mul+add 32" begin
            let N = 100
                a = 2.5f0
                x = rand(Float32, N)
                y = similar(x)

                cnt = @count_ops my_axpy!(a, x, y)
                @test cnt.add32 == N
                @test cnt.mul32 == N
                @test GFlops.flop(cnt) == 2*N


                m = rand(Float32, N, N)
                v = rand(Float32, N)

                cnt = @count_ops(my_prod(m, v))
                @test cnt.add32 == N*N
                @test cnt.mul32 == N*N
                @test GFlops.flop(cnt) == 2*N*N
            end
        end

        @testset "sqrt" begin
            let cnt = @count_ops sqrt(4.2)
                @test cnt.sqrt64 == 1
                @test GFlops.flop(cnt) == 1
            end

            let cnt = @count_ops sqrt(4.2f0)
                @test cnt.sqrt32 == 1
                @test GFlops.flop(cnt) == 1
            end
        end

        @testset "fma" begin
            let cnt = @count_ops fma(1.0, 2.0, 3.0)
                @test cnt.fma64 == 1
                @test GFlops.flop(cnt) == 2
            end

            let cnt = @count_ops fma(1.0f0, 2.0f0, 3.0f0)
                @test cnt.fma32 == 1
                @test GFlops.flop(cnt) == 2
            end
        end

        @testset "interpolated arguments" begin
            let N = 100

                T = Float64
                cnt = @count_ops my_axpy!(pi, $(rand(T, N)), $(rand(T, N)))
                @test cnt.add64 == N
                @test cnt.mul64 == N
                @test GFlops.flop(cnt) == 2*N

                T = Float32
                cnt = @count_ops my_axpy!(pi, $(rand(T, N)), $(rand(T, N)))
                @test cnt.add32 == N
                @test cnt.mul32 == N
                @test GFlops.flop(cnt) == 2*N
            end
        end

        @testset "broadcast" begin
            let N = 100

                x = 42.0
                cnt1 = @count_ops sin(x)
                cnt2 = @count_ops sin.($(fill(x, N)))
                @test GFlops.flop(cnt1) != 0
                @test cnt2 == N*cnt1

                x = 42.0f0
                cnt1 = @count_ops sin(x)
                cnt2 = @count_ops sin.($(fill(x, N)))
                @test GFlops.flop(cnt1) != 0
                @test cnt2 == N*cnt1
            end
        end
    end

    @testset "@gflops" begin
        let
            N = 100
            a = 2.5
            x = rand(N)
            y = Vector{Float64}(undef, N)

            @test @gflops(my_axpy!(a, x, y))          == N
            @test @gflops(my_axpy!(π, $(rand(N)), y)) == N
        end

        let
            N = 100
            m = rand(N, N)
            v = rand(N)
            @test @gflops(my_prod(m, v)) == N*N
        end
    end
end

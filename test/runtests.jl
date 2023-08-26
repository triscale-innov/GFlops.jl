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

# Fake benchmarked times
import BenchmarkTools
GFlops.times(::BenchmarkTools.Trial) = [2.0, 3.0]

@testset "GFlops" begin
    @testset "Counter" begin
        @testset "display empty" begin
            let
                cnt = GFlops.Counter()
                str = string(cnt)
                @test str == "Flop Counter: 0 flop"
            end
        end

        @testset "display non-empty" begin
            let
                cnt = GFlops.Counter()
                cnt.add32 = 1
                str = string(cnt)
                @test  occursin("Float32", str)
                @test !occursin("Float64", str)
                @test  occursin("add",     str)
                @test !occursin("mul",     str)
                @test  occursin(" 1 ",     str)
            end
        end

        @testset "display mixed" begin
            let
                cnt = GFlops.Counter()
                cnt.add32 = 1
                cnt.mul64 = 2
                str = string(cnt)
                @test  occursin("Float32", str)
                @test  occursin("Float64", str)
                @test  occursin("add",     str)
                @test  occursin("mul",     str)
                @test !occursin("div",     str)
                @test  occursin(" 1 ",     str)
                @test  occursin(" 2 ",     str)
            end
        end
    end

    @testset "@count_ops" begin
        @testset "mul+add 64" begin
            let N = 100
                a = 2.5
                x = rand(N)
                y = similar(x)

                cnt = @show @count_ops my_axpy!(a, x, y)
                @test cnt.add64 == N
                @test cnt.mul64 == N
                @test GFlops.flop(cnt) == 2*N


                m = rand(N, N)
                v = rand(N)

                cnt = @show @count_ops(my_prod(m, v))
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

                cnt = @show @count_ops my_axpy!(a, x, y)
                @test cnt.add32 == N
                @test cnt.mul32 == N
                @test GFlops.flop(cnt) == 2*N


                m = rand(Float32, N, N)
                v = rand(Float32, N)

                cnt = @show @count_ops(my_prod(m, v))
                @test cnt.add32 == N*N
                @test cnt.mul32 == N*N
                @test GFlops.flop(cnt) == 2*N*N
            end
        end

        @testset "mul+add 16" begin
            let N = 100
                a = Float16(2.5)
                x = rand(Float16, N)
                y = similar(x)

                cnt = @show @count_ops my_axpy!(a, x, y)
                @test cnt.add16 == N
                @test cnt.mul16 == N
                @test GFlops.flop(cnt) == 2*N


                m = rand(Float16, N, N)
                v = rand(Float16, N)

                cnt = @show @count_ops(my_prod(m, v))
                @test cnt.add16 == N*N
                @test cnt.mul16 == N*N
                @test GFlops.flop(cnt) == 2*N*N
            end
        end

        @testset "neg" begin
            let cnt = @show @count_ops -(4.2)
                @test cnt.neg64 == 1
                @test GFlops.flop(cnt) == 1
            end

            let cnt = @show @count_ops -(4.2f0)
                @test cnt.neg32 == 1
                @test GFlops.flop(cnt) == 1
            end
        end

        @testset "abs" begin
            let cnt = @show @count_ops abs(-4.2)
                @test cnt.abs64 == 1
                @test GFlops.flop(cnt) == 1
            end

            let cnt = @show @count_ops abs(-4.2f0)
                @test cnt.abs32 == 1
                @test GFlops.flop(cnt) == 1
            end
        end

        @testset "sqrt" begin
            let cnt = @show @count_ops sqrt(4.2)
                @test cnt.sqrt64 == 1
                @test GFlops.flop(cnt) == 1
            end

            let cnt = @show @count_ops sqrt(4.2f0)
                @test cnt.sqrt32 == 1
                @test GFlops.flop(cnt) == 1
            end
        end

        # `rem` is a software implementation in Julia 1.9+
        if VERSION < v"1.9"
            @testset "rem" begin
                let cnt = @show @count_ops rem(12.0, 5.0)
                    @test cnt.rem64 == 1
                    @test GFlops.flop(cnt) == 1
                end

                let cnt = @show @count_ops rem(12.0f0, 5.0f0)
                    @test cnt.rem32 == 1
                    @test GFlops.flop(cnt) == 1
                end
            end
        end

        if !(Sys.isapple() && VERSION >= v"1.8")
            @testset "fma" begin
                let cnt = @show @count_ops fma(1.0, 2.0, 3.0)
                    @test cnt.fma64 == 1
                    @test GFlops.flop(cnt) == 2
                end

                let cnt = @show @count_ops fma(1.0f0, 2.0f0, 3.0f0)
                    @test cnt.fma32 == 1
                    @test GFlops.flop(cnt) == 2
                end
            end
        end

        @testset "muladd" begin
            let cnt = @show @count_ops muladd(1.0, 2.0, 3.0)
                @test cnt.muladd64 == 1
                @test GFlops.flop(cnt) == 2
            end

            let cnt = @show @count_ops muladd(1.0f0, 2.0f0, 3.0f0)
                @test cnt.muladd32 == 1
                @test GFlops.flop(cnt) == 2
            end
        end

        @testset "interpolated arguments" begin
            let N = 100

                T = Float64
                cnt = @show @count_ops my_axpy!(pi, $(rand(T, N)), $(rand(T, N)))
                @test cnt.add64 == N
                @test cnt.mul64 == N
                @test GFlops.flop(cnt) == 2*N

                T = Float32
                cnt = @show @count_ops my_axpy!(pi, $(rand(T, N)), $(rand(T, N)))
                @test cnt.add32 == N
                @test cnt.mul32 == N
                @test GFlops.flop(cnt) == 2*N
            end
        end

        @testset "broadcast" begin
            let N = 100

                x = 42.0
                cnt1 = @show @count_ops sin(x)
                cnt2 = @show @count_ops sin.($(fill(x, N)))
                @test GFlops.flop(cnt1) != 0
                @test cnt2 == N*cnt1

                x = 42.0f0
                cnt1 = @show @count_ops sin(x)
                cnt2 = @show @count_ops sin.($(fill(x, N)))
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

            @test @gflops(my_axpy!($a, $x, $y))         == N
            @test @gflops(my_axpy!($π, $(rand(N)), $y)) == N
        end

        let
            N = 100
            m = rand(N, N)
            v = rand(N)
            @test @gflops(my_prod($m, $v)) == N*N
        end
    end
end

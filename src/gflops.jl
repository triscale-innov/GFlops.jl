wrap(x) = x
wrap(x::AbstractFloat) = Float(x)
wrap(x::Array) = wrap.(x)

macro gflops(funcall)
    funcall2 = deepcopy(funcall)

    @assert funcall isa Expr
    @assert funcall.head == :call

    map!(funcall2.args, funcall2.args) do e
        e isa Symbol && return esc(e)
        e isa Expr   || return :(wrap($e))
        e.head == :$ || return :(wrap($e))
        e = esc(e.args[1])
        :(wrap($e))
    end

    quote
        let
            b = @benchmark $funcall
            ns = Statistics.mean(b.times)

            reset()
            $funcall2
            flop = counter

            gflops = flop/ns
            peakfraction = 1e9*gflops / peakflops()
            @printf("  %.2f GFlops,  %.2f%% peak  (%.2e flop, %.2e s)\n",
                    gflops, peakfraction*100,  flop, ns*1e-9)
        end
    end
end

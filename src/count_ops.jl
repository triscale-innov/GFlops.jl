wrap(x) = x
wrap(x::AbstractFloat) = Float(x)
wrap(x::Array) = wrap.(x)

function wrap_args(funcall)
    wrapped = deepcopy(funcall)

    @assert funcall isa Expr
    @assert funcall.head == :call

    wrapped.args[1] = esc(wrapped.args[1])
    map!(@view(wrapped.args[2:end]), @view(wrapped.args[2:end])) do e
        e isa Symbol && return :(wrap($(esc(e))))
        e isa Expr   || return :(wrap($e))
        e.head == :$ || return :(wrap($e))
        e = esc(e.args[1])
        :(wrap($e))
    end
    wrapped
end

macro count_ops(funcall)
    wrapped_funcall = wrap_args(funcall)

    quote
        let
            reset()
            $wrapped_funcall
            counter
        end
    end
end

macro gflops(funcall)
    wrapped_funcall = wrap_args(funcall)

    quote
        let
            b = @benchmark $funcall
            ns = Statistics.mean(b.times)

            reset()
            $wrapped_funcall
            flop = counter

            gflops = flop/ns
            peakfraction = 1e9*gflops / peakflops()
            @printf("  %.2f GFlops,  %.2f%% peak  (%.2e flop, %.2e s)\n",
                    gflops, peakfraction*100,  flop, ns*1e-9)
            gflops
        end
    end
end

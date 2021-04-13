@eval mutable struct Counter
    $((:($(Symbol(op[1], typ[2])) ::Int) for op in ops for typ in typs)...)
    Counter() = new($((0 for _ in 1:length(ops)*length(typs))...))
end

# Relatively inefficient, but there should be no need for performance here...

function flop(c::Counter)
    total = 0
    for (typ, suffix) in typs
        for (name, op, cnt) in ops
            fieldname = Symbol(name, suffix)
            total += cnt * getfield(c, fieldname)
        end
    end
    total
end

import Base: ==, *, show

function Base.show(io::IO, c::Counter)
    type_names  = [typ    for (typ, _)    in typs]
    type_suffix = [suffix for (_, suffix) in typs]
    op_names    = [name   for (name, _)   in ops]

    mat = [getfield(c, Symbol(name, suffix)) for
           name   in op_names,
           suffix in type_suffix]

    fl = flop(c)
    print(io, "Flop Counter: $fl flop")
    fl == 0 && return

    print(io, "\n")
    fc(data, i) = any(data[:,i] .> 0)
    fr(data, i) = any(data[i,:] .> 0)
    pretty_table(io, mat,
                 header = type_names,
                 row_names = op_names,
                 filters_col = (fc,),
                 filters_row = (fr,),
                 newline_at_end = false)
end

function ==(c1::Counter, c2::Counter)
    all(getfield(c1, field)==getfield(c2, field) for field in fieldnames(Counter))
end

function *(n::Int, c::Counter)
    ret = Counter()
    for field in fieldnames(Counter)
        setfield!(ret, field, n*getfield(c, field))
    end
    ret
end

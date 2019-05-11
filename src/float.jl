struct Float{T} <: AbstractFloat
    val :: T
end

(::Type{Float{T}})(x::Float) where {T} = Float(x.val)
Base.promote_rule(::Type{Float{T1}}, ::Type{T2}) where {T1, T2} = Float{promote_type(T1,T2)}
Base.promote_rule(::Type{Float{T1}}, ::Type{Float{T2}}) where {T1, T2} = Float{promote_type(T1,T2)}

counter = 0
reset() = global counter=0

for op in (:+, :*, :-, :/)
    @eval function Base.$op(a::Float, b::Float)
        global counter += 1
        Float($op(a.val, b.val))
    end
end

Base.:<(a::Float, b::Float) = a.val < b.val
Base.:-(a::Float) = Float(-a.val)

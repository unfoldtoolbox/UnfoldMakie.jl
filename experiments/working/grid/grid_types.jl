# Core data containers shared across the grid builder, plotting, and exports.

Base.@kwdef struct TopoplotDomain
    xg::Vector{Float32}
    yg::Vector{Float32}
    mask::BitMatrix
    center::Point2f
    polygon::Vector{Point2f}
    bbox::NTuple{4,Float32}
    area::Float64
    equivalent_radius::Float64
end

Base.@kwdef struct RegionLayout64
    name::Symbol
    title::String
    domain::TopoplotDomain
    seeds::Vector{Point2f}
    weights::Vector{Float64}
    cells::Vector{Vector{Point2f}}
    metrics::NamedTuple
    regions::Vector{NamedTuple}
end

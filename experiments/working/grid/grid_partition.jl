using CairoMakie
using GeometryBasics: Point2f
using Printf
using Random
using Statistics
using TopoPlots
using UnfoldMakie
using UnfoldSim

@isdefined(map_template_to_head) ||
    include(joinpath(@__DIR__, "..", "region_detection", "geometry.jl"))
@isdefined(region_weights_from_grid) ||
    include(joinpath(@__DIR__, "..", "region_detection", "scoring.jl"))
@isdefined(RegionGrid64Config) || include(joinpath(@__DIR__, "region_grid64_config.jl"))

include(joinpath(@__DIR__, "grid_types.jl"))
include(joinpath(@__DIR__, "grid_geometry.jl"))
include(joinpath(@__DIR__, "grid_builder.jl"))
include(joinpath(@__DIR__, "grid_export.jl"))

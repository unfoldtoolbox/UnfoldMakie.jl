using UnfoldSim
using Test
using CairoMakie
using GeometryBasics
using DataFrames
using TopoPlots
using Colors
using Statistics
using AlgebraOfGraphics
using Random
include("../docs/example_data.jl")

raw_ch_names = example_data("raw_ch_names")

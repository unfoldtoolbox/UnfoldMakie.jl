using UnfoldSim
using Test
using CairoMakie
using GeometryBasics
using DataFrames
using TopoPlots
using Colors
using Statistics

include("../docs/example_data.jl")

raw_ch_names = [
    "FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7", "P9", "PO7", "PO3", "O1",
    "Oz", "Pz", "CPz", "FP2", "Fz", "F4", "F8", "FC4", "FCz", "Cz",
    "C4", "C6", "P4", "P8", "P10", "PO8", "PO4", "O2",
]

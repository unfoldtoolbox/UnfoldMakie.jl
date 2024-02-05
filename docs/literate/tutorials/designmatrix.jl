# [Designmatrix Visualization](@id dm_vis)

# Here we discuss design matrix visualization. 
# Make sure you have looked into the [installation instructions](@ref install_instruct) section. 

# # Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie

## Data

include("../../../example_data.jl")
uf = example_data("UnfoldLinearModel")

## Plot Designmatrices

# The following code will result in the default configuration. 

plot_designmatrix(designmatrix(uf))

# To make the design matrix easier to read, you may want to sort it using `sort_data`.

plot_designmatrix(designmatrix(uf); sort_data = true)

# # Configurations for Design matrix plot

# ```@docs
# plot_designmatrix
# ```

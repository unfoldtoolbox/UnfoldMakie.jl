# [ERP Image Visualization](@id erpi_vis)

# Here we discuss ERP image visualization. 
# Make sure you have looked into the [installation instructions](@ref install_instruct).

# # Package loading

using Unfold
using UnfoldMakie
using CairoMakie
using UnfoldSim
include("../../../example_data.jl")

# # Plot ERP image

# The following code will result in the default configuration. 

data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
plot_erpimage(data)

# # Additional features

# Since ERP images use a `Matrix` as an input, the library does not need any informations about the mapping.

#=
- `erpblur` (Number, `10`): number indicating how much blur is applied to the image; 
    Gaussian blur of the ImageFiltering module is used.
    Non-Positive values deactivate the blur.
- `meanplot` (bool, `false`): Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.
=#

plot_erpimage(
    data;
    meanplot = true,
    colorbar = (label = "Voltage [µV]",),
    visual = (colormap = :viridis, colorrange = (-40, 40)),
)

# # Sorted ERP image

# First, generate a data. Second, specify the necessary sorting parameter. 

#=
- `sortvalues` (bool, `false`): parameter over which plot will be sorted. Using sortperm() of Base Julia. 
- `sortperm()` computes a permutation of the array's indices that puts the array into sorted order. 
=#

dat_e, evts, times = example_data("sort_data")
plot_erpimage(times, dat_e; sortvalues = evts.Δlatency)

# # Configurations for ERP image

# ```@docs
# plot_erpimage
# `

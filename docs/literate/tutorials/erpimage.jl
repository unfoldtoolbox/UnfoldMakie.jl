# # ERP image

# **ERP image** is a plot type for visualizing EEG activity for all trials. 
# It can fully represent time and trial dimensions using a heatmap. 
# Y-axis represents all trials, x-axis represents time, while color represents voltage. 
# The ERP image can also be sorted by specific experimental variables, which helps to reveal important correlations. 

# # Setup
# Package loading


using Unfold
using UnfoldMakie
using CairoMakie
using UnfoldSim
using Statistics

# Data input

include("../../../example_data.jl")
data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
plot_erpimage(data)

# # Plot ERP image

# The following code will result in the default configuration. 

# # Sorted ERP image

# Generate the data and specify the necessary sorting parameter. 

#=
- `sortvalues::Vector{Int64} = false` 
    Parameter over which plot will be sorted. Using `sortperm()` of Base Julia. 
    `sortperm()` computes a permutation of the array's indices that puts the array in sorted order.
=#

dat_e, evts, times = example_data("sort_data")
dat_norm = dat_e[:, :] .- mean(dat_e, dims = 2) # normalisation
plot_erpimage(times, dat_norm; sortvalues = evts.Δlatency)

# To see the effect of sorting and normalization, also check this figure.

f = Figure()
plot_erpimage!(f[1, 1], times, dat_e; axis = (; ylabel = "test"))
plot_erpimage!(
    f[2, 1],
    times,
    dat_e;
    sortvalues = evts.Δlatency,
    axis = (; ylabel = "test"),
)
plot_erpimage!(f[1, 2], times, dat_norm;)
plot_erpimage!(f[2, 2], times, dat_norm; sortvalues = evts.Δlatency)
f


# # Additional features

# Since ERP images use a `Matrix` as an input, the library does not need any informations about the mapping.

#=
- `erpblur::Number = 10` 
    Number indicating how much blur is applied to the image.
    Gaussian blur of the `ImageFiltering` module is used.
- `meanplot::bool = false` 
    Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.
=#

# Example of mean plot
plot_erpimage(
    data;
    meanplot = true,
    colorbar = (label = "Voltage [µV]",),
    visual = (colormap = :viridis, colorrange = (-40, 40)),
)

# Example of mean plot and plot of sorted values
plot_erpimage(
    times,
    dat_e;
    sortvalues = evts.Δlatency,
    meanplot = true,
    show_sortval = true,
)

# # Configurations for ERP image

# ```@docs
# plot_erpimage
# ```

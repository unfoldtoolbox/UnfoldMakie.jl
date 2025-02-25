# # Channel image 

# **Channel image** is a plot type for visualizing EEG activity for all channels. 
# It can fully represent time and channel dimensions using a heatmap. 
# Y-axis represents all channels, x-axis represents time, while color represents voltage. 

# # Setup
# Package loading

using Unfold
using UnfoldMakie
using CairoMakie
using UnfoldSim
include("../../../example_data.jl")

# # Plot Channel image

# The following code will result in the default configuration. 

data, pos = TopoPlots.example_data()
data = data[:, :, 1]
pos = pos[1:30]
raw_ch_names = example_data("raw_ch_names");


plot_channelimage(data[1:30, :], pos, raw_ch_names; axis = (; xlabel = "Time [s]"))

# # Configurations for Channel image

# ```@docs
# plot_channelimage
# ```

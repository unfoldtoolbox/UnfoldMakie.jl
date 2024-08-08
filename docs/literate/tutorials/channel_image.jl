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
raw_ch_names = ["FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7", "P9", "PO7",
    "PO3", "O1", "Oz", "Pz", "CPz", "FP2", "Fz", "F4", "F8", "FC4", "FCz", "Cz",
    "C4", "C6", "P4", "P8", "P10", "PO8", "PO4", "O2"]


plot_channelimage(data[1:30, :], pos, raw_ch_names;)

# # Configurations for Channel image

# ```@docs
# plot_channelimage
# ```

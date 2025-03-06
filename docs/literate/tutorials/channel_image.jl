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
using TopoPlots

# # Plot Channel image

# The following code will result in the default configuration. 

dat, pos = TopoPlots.example_data()
dat = dat[:, :, 1]
pos = pos[1:30]
channels_30 = example_montage("channels_30");


plot_channelimage(dat[1:30, :], pos, channels_30; axis = (; xlabel = "Time [s]"))

# # Configurations for Channel image

# ```@docs
# plot_channelimage
# ```

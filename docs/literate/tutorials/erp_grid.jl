# # ERP grid 
# **ERP grid** is a plot type for visualisation of Event-related potentials. 
# It can fully represent time, channel, and layout (channel locations) dimensions using lines. It can also partially represent condition dimensions.
# Lines are displayed on a grid. The location of each axis represents the location of the electrode.
# This plot type is not as popular because it is too cluttered. 

# # Setup
# Package loading

using Unfold
using UnfoldMakie
using CairoMakie
using UnfoldSim
include("../../../example_data.jl")

# # Plot ERP grid

data, pos = TopoPlots.example_data()
data = data[:, :, 1]
channels_32, positions_32 = example_data("montage_32")


plot_erpgrid(data, pos; axis = (; xlabel = "s", ylabel = "µV"))

# # Adding labels

plot_erpgrid(data, pos; drawlabels = true, axis = (; xlabel = "s", ylabel = "µV"))

# # Customizing coordinates
# You can adjust the coordinates of subplots to improve their alignment.
# One simple method is rounding the coordinates to specific intervals.

# Example: Rounding the y-coordinate by 3 precision digits.
pos_new = [Point2(p[1], round(p[2], digits = 3)) for p in positions_32]
plot_erpgrid(data[1:32, :], pos_new, channels_32; drawlabels = true)

# To manually adjust the position of a specific subplot, modify its coordinates using `Point()` with arithmetic operations.

# Example: Shifting the first subplot 0.1 units upward on the y-axis.
pos_new[31] = Point(pos_new[31][1] + 0.2, pos_new[31][2]) # P9
plot_erpgrid(data[1:32, :], pos_new, channels_32; drawlabels = true)

# Hint: you can ask any AI assistant to generate a montage coordinates and channel names you wish. They are quite good at them
# # Configurations for Channel image

# ```@docs
# plot_erpgrid
# ```

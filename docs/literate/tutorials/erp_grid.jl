# # ERP grid 
# **ERP grid** is a plot type for visualisation of Event-related potentials. 
# It can fully represent time, channel, and layout dimensions using lines. It can also partially represent condition dimensions.
# Lines are displayed on a grid. The location of each axis represents the location of the electrode.
# This plot type is not as popular because it is too cluttered. 

# # Setup
# ## Package loading

using Unfold
using UnfoldMakie
using CairoMakie
using UnfoldSim
include("../../../example_data.jl")

# # Plot ERP grid

data, pos = TopoPlots.example_data()
data = data[:, :, 1]


f = Figure()
plot_erpgrid!(f[1, 1], data, pos; axis = (; xlabel = "s", ylabel = "µV"))
f

# # Configurations for Channel image

# ```@docs
# plot_erpgrid
# ```

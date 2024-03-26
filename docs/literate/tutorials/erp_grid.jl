## ERP grid 

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

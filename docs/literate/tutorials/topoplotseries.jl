# # Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using Statistics

# # Plot Topoplot Series

# ## Example data

# In case you do not already have data, you can get example data from the `TopoPlots` module. 
# You can do it like this:

data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)));
nothing #hide

# # Plotting

Δbin = 80
plot_topoplotseries(df, Δbin; positions = positions)

# # Additional features

# ## Disabling colorbar

plot_topoplotseries(df, Δbin; positions = positions, layout = (; use_colorbar = false))

# ## Aggregating functions
# In this example `combinefun` is specified by `mean`, `median` and `std`. 

f = Figure()
plot_topoplotseries!(f[1, 1], df, Δbin; positions = positions, combinefun = mean, axis = (; title = "combinefun = mean"))
plot_topoplotseries!(f[2, 1], df, Δbin; positions = positions, combinefun = median, axis = (; title = "combinefun = median"))
plot_topoplotseries!(f[3, 1], df, Δbin; positions = positions, combinefun = std, axis = (; title = "combinefun = std"))
f


# # Configurations of Topoplot series

# ```@docs
# plot_topoplotseries
# ```

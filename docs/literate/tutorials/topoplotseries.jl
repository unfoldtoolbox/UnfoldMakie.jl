# Topoplot Series is a plot type for visualizing EEG activity in a given time frame or time interval. 
# It can fully represent channel and channel location dimensions using contour lines. It can also partially represent the time dimension.
# Basically, it is a series of Topoplots.

# # Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using Statistics

# # Plot Topoplot series

# ## Example data


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

f = Figure(size = (500, 500))
plot_topoplotseries!(
    f[1, 1],
    df,
    Δbin;
    positions = positions,
    combinefun = mean,
    axis = (; title = "combinefun = mean"),
)
plot_topoplotseries!(
    f[2, 1],
    df,
    Δbin;
    positions = positions,
    combinefun = median,
    axis = (; title = "combinefun = median"),
)
plot_topoplotseries!(
    f[3, 1],
    df,
    Δbin;
    positions = positions,
    combinefun = std,
    axis = (; title = "combinefun = std"),
)
f

# ## Faceting

#=
If you need to plot many topoplots, you should display them in multiple rows. 

Here you can specify:
- Grouping condition using `mapping.row`.
- Label the y-axis with `axis.ylabel`.
- Hide electrode markers with `visual.label_scatter`.
- Change the color map with `visual.colormap`. The default is `Reverse(:RdBu)`.
- Adjust the limits of the topoplot boxes with `xlim_topo` and `ylim_topo`. By default both are `(-0.25, 1.25)`.
- Adjust the size of the figure with `Figure(size = (x, y))`.
- Adjust the padding between topoplot labels and axis labels using `xlabelpadding` and `ylabelpadding`.
=#
df1 = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
df1.condition = repeat(["A", "B", "C", "D", "E"], size(df, 1) ÷ 5)

f = Figure(size = (600, 500))

plot_topoplotseries!(
    f[1:2, 1:2],
    df1,
    Δbin;
    col_labels = true,
    mapping = (; row = :condition),
    axis = (; ylabel = "Conditions"),
    positions = positions,
    visual = (label_scatter = false,),
    layout = (; use_colorbar = true),
)
f

# # Configurations of Topoplot series

# ```@docs
# plot_topoplotseries
# ```

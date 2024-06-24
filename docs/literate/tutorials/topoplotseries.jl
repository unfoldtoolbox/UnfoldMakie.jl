# # Topoplot Series

# **Topoplot series** is a plot type for visualizing EEG activity in a given time frame or time interval. 
# It can fully represent channel and channel location dimensions using contour lines. It can also partially represent the time dimension.
# Basically, it is a series of Topoplots.

# # Setup
# ## Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using Statistics

# ## Data input


data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)));
nothing #hide


# # Number of topoplots
# There are two ways to specify the number of topoplots in a topoplot series: 
# 1) `bin_width` - specify the interval between topoplots

bin_width = 80
plot_topoplotseries(df; bin_width, positions = positions)

# 2) `bin_num` - specify the number of topoplots

plot_topoplotseries(df; bin_num = 5, positions = positions)

# # Categorical and contionous x-values
# x-value could be contionous (`time` by deafult, but could be saccade amplitude, contrast) or categorical (any experimental variable).

f = Figure()
df_cat = UnfoldMakie.eeg_matrix_to_dataframe(data[:, 1:5, 1], string.(1:length(positions)))
df_cat.condition = repeat(["A", "B", "C", "D", "E"], size(df_cat, 1) ÷ 5)

plot_topoplotseries!(
    f[1, 1],
    df_cat;
    mapping = (; col = :condition),
    axis = (; xlabel = "Conditions"),
    positions = positions,
)
f

#=
To create topoplot series with categorical values:
- Do not specify `bin_width` or `bin_num`.
- Put categorical value in `mapping.col`.
=#

# # Additional features

# ## Adjusting contours

plot_topoplotseries(
    df;
    bin_width,
    positions = positions,
    visual = (; enlarge = 0.9,
    contours = (; linewidth = 1, color = :black)),
)

# ## Aggregating functions
# In this example `combinefun` is specified by `mean`, `median` and `std`. 

f = Figure(size = (500, 500))
plot_topoplotseries!(
    f[1, 1],
    df;
    bin_width,
    positions = positions,
    combinefun = mean,
    axis = (; xlabel = "", title = "combinefun = mean"),
)
plot_topoplotseries!(
    f[2, 1],
    df;
    bin_width,
    positions = positions,
    combinefun = median,
    axis = (; xlabel = "", title = "combinefun = median"),
)
plot_topoplotseries!(
    f[3, 1],
    df;
    bin_width,
    positions = positions,
    combinefun = std,
    axis = (; title = "combinefun = std"),
)
f

# ## Multiple rows

#=
Use `nrows` to specify multiple rows. 
=#

f = Figure()
df_col = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
plot_topoplotseries!(
    f[1, 1:5],
    df_col;
    bin_num = 14,
    nrows = 4,
    positions = positions,
    visual = (; label_scatter = false),
)
f

# # Configurations of Topoplot series

#=
Also you can:
- Label the x-axis with `axis.xlabel`.
- Hide electrode markers with `visual.label_scatter`.
- Change the color map with `visual.colormap`. The default is `Reverse(:RdBu)`.
- Adjust the limits of the topoplot boxes with `axis.xlim_topo` and `axis.ylim_topo`. By default both are `(-0.25, 1.25)`.
- Adjust the size of the figure with `Figure(size = (x, y))`.
- Adjust the padding between topoplot labels and axis labels using `xlabelpadding` and `ylabelpadding`.
=#
# ```@docs
# plot_topoplotseries
# ```

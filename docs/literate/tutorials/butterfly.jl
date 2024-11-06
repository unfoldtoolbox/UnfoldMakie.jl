# # [Butterfly Plot](@id bfp_vis)
# **Butterfly plot** is a plot type for visualisation of Event-related potentials. 
# It can fully represent time and channels dimensions using lines. With addition of topoplot inset it can also represent location of channels.
# It called "butterfly" because the envelope of channels reminds butterfly wings🦋. 

# The configurations of [ERP plots](@ref erp_vis) and Butterfly plots are somehow similar.

# # Setup
# Package loading

# The following modules are necessary for run this tutorial:

using UnfoldMakie
using Unfold
using CairoMakie
using DataFrames
using Colors

# Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

# Data

# We filter the data to make it more clearly represented:

include("../../../example_data.jl")
df, pos = example_data("TopoPlots.jl")
first(df, 3)

# # Plot Butterfly Plots

# The default butterfly plot:

plot_butterfly(df)

# The butterfly plot with corresponding topoplot. You need to provide the channel positions.

plot_butterfly(df; positions = pos)

# You want to change size of topoplot markers and size of topoplot:

plot_butterfly(
    df;
    positions = pos,
    topo_attributes = (; label_scatter = (; markersize = 30)),
    topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
)

# You want to add vline and hline:

f = Figure()
plot_butterfly!(f, df; positions = pos)
hlines!(0, color = :gray, linewidth = 1)
vlines!(0, color = :gray, linewidth = 1)
f

# You want to remove all decorations:

plot_butterfly(
    df;
    positions = pos,
    layout = (; hidedecorations = (:label => true, :ticks => true, :ticklabels => true)),
)

# # Changing the colors of channels

# Please check [this page](@ref pos2color).

# You want to highlight a specific channel or channels. 
# Specify channels first:

df.highlight1 = in.(df.channel, Ref([12])) # for single channel
df.highlight2 = in.(df.channel, Ref([10, 12])) # for multiple channels
nothing #hide 

# Second, you can highlight it or them by color.

gray = Colors.RGB(128 / 255, 128 / 255, 128 / 255)
f = Figure(size = (1000, 400))
plot_butterfly!(
    f[1, 1],
    df;
    positions = pos,
    mapping = (; color = :highlight1),
    visual = (; color = 1:2, colormap = [gray, :red]),
)
plot_butterfly!(
    f[1, 2],
    df;
    positions = pos,
    mapping = (; color = :highlight2),
    visual = (; color = 1:2, colormap = [gray, :red]),
)
f

# Or by faceting:

df.highlight2 = replace(df.highlight2, true => "channels 10, 12", false => "all channels")

plot_butterfly(
    df;
    positions = pos,
    mapping = (; color = :highlight2, col = :highlight2),
    visual = (; color = 1:2, colormap = [gray, :red]),
)

# # Column Mappings

# Since butterfly plots use a `DataFrame` as input, the library needs to know the names of the columns used for plotting. You can set these mapping values by calling `plot_butterfly(...; mapping=(; :x=:time))`. Just specify a `NamedTuple`. Note the `;` right after the opening parentheses.

# # Configurations of Butterfly Plot

# ```@docs
# plot_butterfly
# ```

# # [Butterfly Plot Visualization](@id bfp_vis)
# Here we discuss Butterfly plot visualization.
# Since the configurations for ERP plots can be applied to butterfly plots as well. [Here](@ref erp_vis) you can find the configurations for ERP plots.

# # Package loading

# The following modules are necessary for run this tutorial:

using UnfoldMakie
using Unfold
using CairoMakie
using DataFrames

# Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

# # Data

# We filter the data to make it more clearly represented:

include("../../../example_data.jl")
df, pos = example_data("TopoPlots.jl")
first(df, 3)

# # Plot Butterfly Plots

# The default butterfly plot:

plot_butterfly(df)

# The butterfly plot with corresponding topoplot. You need to provide the channel positions.

plot_butterfly(df; positions = pos)

# You want to change size of topomarkers and size of topoplot:

plot_butterfly(df; positions = pos, topomarkersize = 10, topoheigth = 0.4, topowidth = 0.4)

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

# # Changing the Corlor of Channels

# Please check [this page](@id pos2color).

# # Column Mappings for Butterfly Plot

# Since butterfly plots use a `DataFrame` as input, the library needs to know the names of the columns used for plotting. You can set these mapping values by calling `plot_butterfly(...; mapping=(; :x=:time))`. Just specify a `NamedTuple`. Note the `;` right after the opening parentheses.

# # Configurations of Butterfly Plot

# ```@docs
# plot_butterfly
# ```

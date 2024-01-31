# [Change Butterfly Channel Position Color](@id ht_p2c)

# In this section we discuss how users are able change the position to colorscale of the legendtopo in the butterfly plot.

using UnfoldMakie
using CairoMakie
using DataFramesMeta
using Colors

# By default the plot looks like this:

include("../../../example_data.jl")
results, positions = example_data("TopoPlots.jl")
plot_butterfly(results; positions = positions)


# We can switch the colorscale of the position-map, by giving a function that maps from a `(x,y)` tuple to a color. UnfoldMakie currently provides three different ones `pos2colorRGB` (same as MNE-Python), `pos2colorHSV` (HSV colorspace), `pos2colorRomaO`. Whereas `RGB` & `HSV` have the benefits of being 2D colormaps, `Roma0` has the benefit of being perceptualy uniform.


# ## Similar to MNE

plot_butterfly(
    results;
    positions = positions,
    topopositions_to_color = pos -> UnfoldMakie.posToColorRGB(pos),
)


# ## HSV-Space

plot_butterfly(
    results;
    positions = positions,
    topopositions_to_color = UnfoldMakie.posToColorHSV,
)


# ## Uniform Color
# To highlight the flexibility, we can also make all lines `gray`, or any other arbitrary color, or function of electrode-`position`.


plot_butterfly(
    results;
    positions = positions,
    topopositions_to_color = x -> Colors.RGB(0.5),
)

# # [Spline plot](@id spline_vis)
# **Spline plot** (aka topography plot) is a plot type for visualisation of spline basises.


# # Setup
# Package and data loading

using Unfold, UnfoldMakie
using BSplineKit


include("../../../example_data.jl")
df, pos = example_data("TopoPlots.jl")
m1 = example_data("UnfoldLinearModelwith1Spline")
m2 = example_data("UnfoldLinearModelwith2Splines")


# Spline plot with one spline term
plot_splines(m1)

# Spline plot with two spline terms
plot_splines(m2)

# # Configurations of Butterfly Plot

# ```@docs
# plot_splines
# ```

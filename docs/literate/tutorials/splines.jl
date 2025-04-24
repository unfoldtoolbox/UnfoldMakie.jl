# # [Spline plot](@id spline_vis)
# **Spline plot** is a plot type for visualisation of  terms in an UnfoldModel. 
# Two subplots are generated for each spline term: 1) the basis function of the spline; 2) the density of the underlying covariate.

# Multiple spline terms are arranged across columns.
# Dashed lines indicate spline knots.

# # Setup
# **Package and data loading**

using Unfold, UnfoldMakie
import BSplineKit, DataFrames

df, pos = UnfoldMakie.example_data("TopoPlots.jl")
m1 = UnfoldMakie.example_data("UnfoldLinearModelwith1Spline");
m2 = UnfoldMakie.example_data("UnfoldLinearModelwith2Splines");


# Spline plot with one spline term:
plot_splines(m1)

# Spline plot with two spline terms:
plot_splines(m2)

# # Configurations of Spline plot

# ```@docs
# plot_splines
# ```

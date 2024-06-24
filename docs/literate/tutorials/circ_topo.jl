# # Circular Topoplots

# **Circular topoplot series** is a plot type for visualizing EEG activity in relation to some continous variable arranged on a circluar line. 
# It can fully represent channel and channel location dimensions using contour lines. It can also partially represent the varaible dimension.
# Variable could be for instance saccadic amplitude or degrees of visual angle. 
# Basically, it is a series of Topoplots arranged on a circle.

# # Setup
# ## Package loading

using UnfoldMakie
using CairoMakie
using TopoPlots # for example data
using Random
using DataFrames


# ## Data generation
# Generate a `Dataframe`. We need to specify the Topoplot positions either via `position`, or via `labels`.
data, pos = TopoPlots.example_data();
dat = data[:, 240, 1]
df = DataFrame(
    :estimate => eachcol(Float64.(data[:, 100:40:300, 1])),
    :circular_variable => [0, 50, 80, 120, 180, 210],
    :time => 100:40:300,
)
df = flatten(df, :estimate);

# # Plot generations
# Note how the plots are located at the angles of the `circular_variable`.
plot_circular_topoplots(
    df;
    positions = pos,
    center_label = "Relative angle [°]",
    predictor = :circular_variable,
)

# If the bounding variable is not between 0 and 360, since we are using time, we must specify it. 
plot_circular_topoplots(
    df;
    positions = pos,
    center_label = "Time [sec]",
    predictor = :time,
    predictor_bounds = [80, 320],
)

# # Configurations of Circular Topoplots

# ```@docs
# plot_circular_topoplots
# ```

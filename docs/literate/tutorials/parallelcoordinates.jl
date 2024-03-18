# Here we discuss parallel coordinates plot (PCP) visualization. 

# # Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie


# # Data generation

include("../../../example_data.jl")
r1, positions = example_data();
r2 = deepcopy(r1)
r2.coefname .= "B" # create a second category
r2.estimate .+= rand(length(r2.estimate)) * 0.1
results_plot = vcat(r1, r2);
nothing #hide


# # Plot PCPs

plot_parallelcoordinates(
    subset(results_plot, :channel => x -> x .<= 5);
    mapping = (; color = :coefname),
)

# # Additional features

# ## Normalization

#=
On the first image, there is no normalization and the extremes of all axes are the same and equal to the max and min values across all chanells. 
On the second image, there is a `minmax normalization``, so each axis has its own extremes based on the min and max of the data.

Typically, parallelplots are normalized per axis. Whether this makes sense for estimating channel x, we do not know.
=#

f = Figure()
plot_parallelcoordinates(
    f[1, 1],
    subset(results_plot, :channel => x -> x .< 10);
    mapping = (; color = :coefname),
    axis = (; title = "normalize = nothing"),
)
plot_parallelcoordinates(
    f[2, 1],
    subset(results_plot, :channel => x -> x .< 10);
    mapping = (; color = :coefname),
    normalize = :minmax,
    axis = (; title = "normalize = :minmax"),
)
f

# ## Color schemes

# Use only categorical with high contrast between adjacent colors. 
# More: https://docs.makie.org/stable/explanations/colors/index.html

f = Figure()
plot_parallelcoordinates(
    f[1, 1],
    subset(results_plot, :channel => x -> x .<= 5);
    mapping = (; color = :coefname),
    visual = (; colormap = :tab10),
    axis = (; title = "colormap = tab10"),
)
plot_parallelcoordinates(
    f[2, 1],
    subset(results_plot, :channel => x -> x .<= 5);
    mapping = (; color = :coefname),
    visual = (; colormap = :Accent_3),
    axis = (; title = "colormap = Accent_3"),
)
f

# ## Labels

# Use `ax_labels` to specify labels for the axes.

plot_parallelcoordinates(
    subset(results_plot, :channel => x -> x .< 5);
    visual = (; color = :darkblue),
    ax_labels = ["Fz", "Cz", "O1", "O2"],
)

# ## Tick labels

# Specify tick labels on axis. There are four different options for the tick labels.


f = Figure(size = (400, 800))
plot_parallelcoordinates(
    f[1, 1],
    subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
    ax_labels = ["Fz", "Cz", "O1", "O2"],
    ax_ticklabels = :all,
    normalize = :minmax,
    axis = (; title = "ax_ticklabels = :all"),
) # show all ticks on all axes
plot_parallelcoordinates(
    f[2, 1],
    subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
    ax_labels = ["Fz", "Cz", "O1", "O2"],
    ax_ticklabels = :left,
    normalize = :minmax,
    axis = (; title = "ax_ticklabels = :left"),
) # show all ticks on the left axis, but only extremities on others 
plot_parallelcoordinates(
    f[3, 1],
    subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
    ax_labels = ["Fz", "Cz", "O1", "O2"],
    ax_ticklabels = :outmost,
    normalize = :minmax,
    axis = (; title = "ax_ticklabels = :outmost"),
) # show ticks on extremities of all axes

plot_parallelcoordinates(
    f[4, 1],
    subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
    ax_labels = ["Fz", "Cz", "O1", "O2"],
    ax_ticklabels = :none,
    normalize = :minmax,
    axis = (; title = "ax_ticklabels = :none"),
) #  disable all ticks
f

# ## Bending the parallel plot

# Bending the linescan be helpful to make them more visible.

f = Figure()
plot_parallelcoordinates(
    f[1, 1],
    subset(results_plot, :channel => x -> x .< 10),
    axis = (; title = "bend = false"),
)
plot_parallelcoordinates(
    f[2, 1],
    subset(results_plot, :channel => x -> x .< 10),
    bend = true,
    axis = (; title = "bend = true"),
)
f


# ## Transparancy 

uf_5chan = example_data("UnfoldLinearModelMultiChannel")

f = Figure()
plot_parallelcoordinates(
    f[1, 1],
    uf_5chan;
    mapping = (; color = :coefname),
    layout = (; legend_position = :right),
    visual = (; alpha = 0.1),
    axis = (; title = "alpha = 0.1"),
)
plot_parallelcoordinates(
    f[2, 1],
    uf_5chan,
    mapping = (; color = :coefname),
    layout = (; legend_position = :right),
    visual = (; alpha = 0.9),
    axis = (; title = "alpha = 0.9"),
)
f

# # Configurations of Parallel coordinates plot

# ```@docs
# plot_parallelcoordinates
# ```

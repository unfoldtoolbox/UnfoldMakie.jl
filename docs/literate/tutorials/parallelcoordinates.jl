# # Parallel Coordinates

# **Parallel Coordinates Plot** (PCP) is a plot type used to visualize EEG activity for some channels. 
# It can fully represent condition and channel dimensions using lines. It can also partially represent time and trials.

# Each vertical axis represents a voltage level for a channel.
# Each line represents a trial, each colour represents a condition. 

# # Setup
# P**ackage loading**

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie

# **Data generation**
r1, positions = UnfoldMakie.example_data();
r2 = deepcopy(r1)
r2.coefname .= "B" # create a second category
r2.estimate .+= rand(length(r2.estimate)) * 0.1
results_plot = vcat(r1, r2);
nothing #hide

# # Plot PCPs

plot_parallelcoordinates(
    subset(results_plot, :channel => x -> x .<= 5);
    mapping = (; color = :coefname),
    ax_labels = ["FP1", "F3", "F7", "FC3", "C3"],
    axis = (; ylabel = "Time [s]"),
)

# # Additional features

# ## Normalization

#=
On the first image, there is no normalization and the extremes of all axes are the same and equal to the max and min values across all chanells. 
On the second image, there is a `minmax normalization`, so each axis has its own extremes based on the min and max of the data.

Typically, parallel plots are normalized per axis. Whether this makes sense for estimating channel x, we do not know.
=#

begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "T7", "CP3", "P3", "P7", "O1"],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
        axis = (; ylabel = "Time [s]", xlabel = "", title = "normalize = nothing"),
    )
    plot_parallelcoordinates(
        f[2, 1],
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "T7", "CP3", "P3", "P7", "O1"],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
        normalize = :minmax,
        axis = (; ylabel = "Time [s]", title = "normalize = :minmax"),
    )
    f
end

# ## Color schemes

# Use only categorical with high contrast between adjacent colors. 
# More: [change colormap](https://docs.makie.org/stable/explanations/colors/index.html).

begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        ax_labels = ["Fz", "Cz", "O1", "O2", "Pz"],
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
        visual = (; colormap = :tab10),
        axis = (; ylabel = "Time [s]", xlabel = "", title = "colormap = tab10"),
    )
    plot_parallelcoordinates(
        f[2, 1],
        ax_labels = ["Fz", "Cz", "O1", "O2", "Pz"],
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
        visual = (; colormap = :Accent_3),
        axis = (; ylabel = "Time [s]", title = "colormap = Accent_3"),
    )
    f
end
# ## Labels

# Use `ax_labels` to specify labels for the axes.

plot_parallelcoordinates(
    subset(results_plot, :channel => x -> x .< 5);
    visual = (; color = :steelblue1),
    ax_labels = ["Fz", "Cz", "O1", "O2"],
    axis = (; ylabel = "Time [s]"),
)

# ## Tick labels

# Specify tick labels on axis. There are four different options for the tick labels.

begin
    f = Figure(size = (500, 900))
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :all,
        normalize = :minmax,
        visual = (; color = :burlywood1),
        axis = (;
            xlabel = "",
            ylabel = "Time [s]",
            ylabelpadding = 40,
            title = "ax_ticklabels = :all",
        ),
    ) # show all ticks on all axes
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :left,
        normalize = :minmax,
        visual = (; color = :cyan3),
        axis = (;
            xlabel = "",
            ylabel = "Time [s]",
            ylabelpadding = 40,
            title = "ax_ticklabels = :left",
        ),
    ) # show all ticks on the left axis, but only extremities on others 
    plot_parallelcoordinates(
        f[3, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :outmost,
        normalize = :minmax,
        visual = (; color = :burlywood1),
        axis = (;
            xlabel = "",
            ylabel = "Time [s]",
            ylabelpadding = 40,
            title = "ax_ticklabels = :outmost",
        ),
    ) # show ticks on extremities of all axes

    plot_parallelcoordinates(
        f[4, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :none,
        normalize = :minmax,
        visual = (; color = :cyan3),
        axis = (; ylabel = "Time [s]", ylabelpadding = 40, title = "ax_ticklabels = :none"),
    ) #  disable all ticks
    f
end
# ## Bending the parallel plot

# Bending the linescan be helpful to make them more visible.

begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "T7", "CP3", "P3", "P7", "O1"],
        subset(results_plot, :channel => x -> x .< 10),
        visual = (; color = :plum),
        axis = (; title = "bend = false", xlabel = "", ylabel = "Time [s]"),
    )
    plot_parallelcoordinates(
        f[2, 1],
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "T7", "CP3", "P3", "P7", "O1"],
        subset(results_plot, :channel => x -> x .< 10),
        bend = true, # here
        visual = (; color = :plum),
        axis = (; title = "bend = true", ylabel = "Time [s]"),
    )
    f
end


# ## Transparancy 

uf_5chan = UnfoldMakie.example_data("UnfoldLinearModelMultiChannel")

begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        uf_5chan;
        mapping = (; color = :coefname),
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3"],
        visual = (; alpha = 0.1),
        axis = (;
            title = "alpha = 0.1",
            xlabel = "",
            ylabel = "Time [s]",
            ylabelpadding = 20,
        ),
    )
    plot_parallelcoordinates(
        f[2, 1],
        uf_5chan,
        mapping = (; color = :coefname),
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3"],
        visual = (; alpha = 0.9),
        axis = (; title = "alpha = 0.9", ylabel = "Time [s]", ylabelpadding = 20),
    )
    f
end

# # Configurations of Parallel coordinates plot

# ```@docs
# plot_parallelcoordinates
# ```

# # Parallel Coordinates

### Parallel Coordinates Plot (PCP)

# A Parallel Coordinates Plot (PCP) is a visualization technique used to represent EEG activity across multiple channels.
#
# - Trial dimension: Each line corresponds to a single trial. Alternatively, trials can be averaged to reduce visual complexity.
# - Channel dimension: Each vertical axis is a channel. Although all channels can be shown, typically only a selected subset is visualized to avoid clutter.
# - Condition and time dimensions: These can be encoded using the color or style of the lines to distinguish between experimental conditions or time windows.
# - Voltage (EEG amplitude): Represented along the y-axis of each vertical axis. The scale can either be fixed across all channels or adjusted per channel, depending on the analysis goal.

# # Setup
# **Package loading**

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

# # Plot PCPs

plot_parallelcoordinates(
    subset(results_plot, :channel => x -> x .<= 5);
    mapping = (; color = :coefname),
    ax_labels = ["FP1", "F3", "F7", "FC3", "C3"],
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
        axis = (; xlabel = "", title = "normalize = nothing"),
    )
    plot_parallelcoordinates(
        f[2, 1],
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "T7", "CP3", "P3", "P7", "O1"],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
        normalize = :minmax,
        axis = (; title = "normalize = :minmax"),
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
        axis = (; xlabel = "", title = "colormap = tab10"),
    )
    plot_parallelcoordinates(
        f[2, 1],
        ax_labels = ["Fz", "Cz", "O1", "O2", "Pz"],
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
        visual = (; colormap = :Accent_3),
        axis = (; title = "colormap = Accent_3"),
    )
    f
end
# ## Labels

# Use `ax_labels` to specify labels for the axes.

plot_parallelcoordinates(
    subset(results_plot, :channel => x -> x .< 5);
    visual = (; color = :steelblue1),
    ax_labels = ["Fz", "Cz", "O1", "O2"],
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
        axis = (; ylabelpadding = 40, title = "ax_ticklabels = :none"),
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
        axis = (; title = "bend = false", xlabel = ""),
    )
    plot_parallelcoordinates(
        f[2, 1],
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "T7", "CP3", "P3", "P7", "O1"],
        subset(results_plot, :channel => x -> x .< 10),
        bend = true, # here
        visual = (; color = :plum),
        axis = (; title = "bend = true"),
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
            ylabelpadding = 20,
        ),
    )
    plot_parallelcoordinates(
        f[2, 1],
        uf_5chan,
        mapping = (; color = :coefname),
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3"],
        visual = (; alpha = 0.9),
        axis = (; title = "alpha = 0.9", ylabelpadding = 20),
    )
    f
end

# # Configurations of Parallel coordinates plot

# ```@docs
# plot_parallelcoordinates
# ```

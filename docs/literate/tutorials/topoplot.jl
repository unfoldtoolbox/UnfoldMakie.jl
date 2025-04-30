# # [Topoplot](@id topo_vis)
# **Topoplot** (aka topography plot) is a plot type for visualisation of EEG activity in a specific time stemp or time interval. 
# It can fully represent channel and channel location dimensions using contour lines.

# The topoplot is a 2D projection and interpolation of the 3D distributed sensor activity. The name stems from physical geography, but instead of height, the contour lines represent voltage levels. 

# # Setup
# **Package loading**

using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots

# **Data loading**

dat, positions = TopoPlots.example_data();

# The size of `data` is 64×400×3. This means:
# - 64 channels;
# - 400 timepoints in range from -0.3 to 0.5 mseconds;
# - Estimates of 3 averaging functions. Instead of displaying the EEG data for all subjects, here we aggregate the data using (1) mean, (2) standard deviation and (3) p-value within t-tests.

# While `position` consist of 64 x and y coordinates of each channels on a scalp. 


# # Plot Topoplots

# Here we select a time point in 340 msec and the mean estimate. 
df = DataFrame(:estimate => dat[:, 340, 1])
plot_topoplot(
    df;
    positions = positions,
    axis = (; xlabel = "340 ms"),
    colorbar = (; height = 350),
)

# ## Setting sensor positions

#=
The `plot_topoplot()` needs the sensor positions to be specified. There are several ways to do this:

- Specify positions directly: `plot_topoplot(...; positions=[...])`
- Specify the sensor labels: `plot_topoplot(...; labels=[...])`

To get the positions from the labels we use a [database](https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv).
=#

# # Column Mappings for Topoplots
#=
When using topoplots with a `DataFrame` as input, the library needs to know the names of the columns used for plotting. This is specified using the `mapping=(;)` kwargs.

While there are several default values that will be checked in order if they exist in the `DataFrame`, a custom name may need to be chosen:

Note that only one of `positions` or `labels` needs to be set to draw a topoplot. If both are set, positions takes precedence, labels can be used to label electrodes in TopoPlots.jl.
=#

# The default columns of mapping could be seen usign this code:

configs_default = UnfoldMakie.PlotConfig()
configs_default.mapping.y

# # Labelling
#=
- `label_text` draws labels next to their positions. 
Example: `plot_topoplot(...; visual=(; label_text = true))`

- `label_scatter (boolean)` draws the markers at the given positions.

Example: `plot_topoplot(...; visual=(; label_scatter = true))`
=#
begin
    f = Figure(size = (500, 500))
    labs4 = ["s1", "s2", "s3", "s4"]
    plot_topoplot!(
        f[1, 1],
        dat[1:4, 340, 1];
        positions = positions[1:4],
        visual = (; label_scatter = false),
        labels = labs4,
        axis = (; xlabel = "", title = "No markers"),
        colorbar = (; height = 100,),
    )

    plot_topoplot!(
        f[2, 1],
        dat[1:4, 340, 1];
        positions = positions[1:4],
        visual = (;
            label_text = true,
            label_scatter = (
                markersize = 15,
                color = "white",
                strokecolor = "green",
                strokewidth = 2,
            ),
        ),
        labels = labs4,
        axis = (; xlabel = "340 ms", title = "Markers with channel labels"),
        mapping = (; labels = labs4),
        colorbar = (; height = 100),
    )
    f
end

# # Highlighting channels
plot_topoplot(dat[:, 50, 1]; positions, high_chan = [1, 2], axis = (; xlabel = "340 ms"))


# # Horizontal colorbars
# Just switch `colorbar.vertical` to `false`
plot_topoplot(
    dat[:, 50, 1];
    positions,
    axis = (; xlabel = "50 ms"),
    colorbar = (; vertical = false, width = 180, label = "Voltage estimate"),
)

# # Advanced markers
# You can use markers and their proeprties as additional information dimension. For instance, to map uncertaitny or some other value to the marker size, color or rotation.
# This is done by setting the `topo_attributes` kwarg. The following example shows how to set the marker size and color based on the data values.
# Check more [here](https://docs.makie.org/dev/reference/plots/scatter#markers).

# Markers as arrows
random_rotations = rand(64) .* 2π
plot_topoplot(
    dat[:, 50, 1];
    positions,
    axis = (; xlabel = "50 ms"),
    topo_attributes = (;
        label_scatter = (;
            markersize = 20,
            marker = '↑',
            color = :black,
            rotation = random_rotations,
        )
    ),
)

# Marker size change
plot_topoplot(
    dat[:, 50, 1];
    positions,
    axis = (; xlabel = "50 ms"),
    topo_attributes = (;
        label_scatter = (; markersize = random_rotations, marker = :circle, color = :black)
    ),
)

# # Configurations of Topoplot

# ```@docs
# plot_topoplot
# ```

# # [Topoplot](@id topo_vis)
# **Topoplot** (aka topography plot) is a plot type for visualisation of EEG activity in a specific time stemp or time interval. 
# It can fully represent channel and channel location dimensions using contour lines.

# The topoplot is a 2D projection and interpolation of the 3D distributed sensor activity. The name stems from physical geography, but instead of height, the contour lines represent voltage levels. 

# # Setup
# **Package loading**

using UnfoldMakie
using DataFrames
using CairoMakie, MakieThemes
using TopoPlots

# **Data loading**

topo_array, topo_positions = TopoPlots.example_data();

# The size of `topo_array` is 64×400×3. This means:
# - 64 channels;
# - 400 timepoints in range from -0.3 to 0.5 mseconds;
# - Estimates of 3 averaging functions. Instead of displaying the EEG data for all subjects, here we aggregate the data using (1) mean, (2) standard deviation and (3) p-value within t-tests.

# While `position` consist of 64 x and y coordinates of each channels on a scalp. 


# # Plot a topoplot

# Let's select a time point in 340 msec and the mean estimate. 
plot_topoplot(
    topo_array[:, 340, 1];
    positions = topo_positions,
    axis = (; xlabel = "Time [340 ms]"),
    colorbar = (; height = 350),
)

# Typical topoplot constist of: 
# 1) the head outline representing time at certain time point or time window, 
# 2) colorbar representing the voltage, 3) markers and labels for each channel (aka sensors, electrodes).

# # Horizontal colorbars
# Colorbars could be vertical or horizontal (practical for multiple topoplots). 
# Just switch `colorbar.vertical` to `false` to make it horizontal.
plot_topoplot(
    topo_array[:, 50, 1];
    positions = topo_positions,
    axis = (; xlabel = "Time [50 ms]"),
    colorbar = (; vertical = false, width = 180),
)

# # Colormaps
# Rules for choosing a good colormap for topoplots:
# 1) It should be "scientific", with a linear progression and a natural ordering of colors;
# 2) It should be diverging;
# 3) It should be color-blind friendly.

begin
    f = Figure(size = (700, 700))
    Label(f[0, 1:3], "Topoplots with Diverging Scientific Colormaps"; fontsize = 22, halign = :center)

    colormaps = [:berlin, :roma, :lisbon, :cork, :managua, :bam]

    for (i, cmap) in enumerate(colormaps)
        r = div(i-1, 3) + 1   # row index (1 or 2)
        c = mod(i-1, 3) + 1   # column index (1 → 3)

        plot_topoplot!(f[r, c],
            topo_array[:, 100, 1];
            positions = topo_positions,
            axis = (; xlabel = "Time [100 ms]", title = string(cmap)),
            colorbar = (; vertical = false, width = 180),
            visual = (; colormap = cmap, contours = false),
        )
    end
    f
end

# # Channel labels
# Changing fonts and font size
# Here we sue arbitrary labels "s1", "s2", ..., "s64" for demonstration. 
# To learn how to use the real channel names, check the section Topo labels.
labels = ["s$i" for i = 1:size(topo_array, 1)]

with_theme(Theme(; fontsize = 25, fonts = (; regular = "Ubuntu Mono"))) do
    plot_topoplot(
        topo_array[:, 340, 1];
        labels,
        positions = topo_positions,
        visual = (; label_text = true),
        axis = (; xlabel = "340 ms"),
    )
end

# Check that the font you choose is available on your PC or GitHub.

# # Highlighting channels 

# Create per-channel styles
colors = fill(:black, 64)      # default
sizes  = fill(8, 64)           # default size
strokes = fill(0.5, 64);        # default width

# Highlight first two
colors[1:2] .= (:red, :red)
sizes[1:2] .= (14, 14)
strokes[1:2] .= (3, 3)

plot_topoplot(
    topo_array[:, 50, 1];
    positions = topo_positions,
    axis = (; xlabel = "Time [50 ms]"),
    topo_attributes = (;
        label_scatter = (; 
            markersize = sizes,
            color = colors,
            strokewidth = strokes,
            strokecolor = colors
        )
    ),
)

# # Advanced markers
# You can use markers and their proeprties as additional information dimension. For instance, to map uncertaitny or some other value to the marker size, color or rotation.
# This is done by setting the `topo_attributes` kwarg. The following example shows how to set the marker size and color based on the data values.
# Check more [here](https://docs.makie.org/dev/reference/plots/scatter#markers).

# Markers as arrows
plot_topoplot(
    topo_array[:, 50, 1];
    positions = topo_positions,
    axis = (; xlabel = "Time [50 ms]"),
    topo_attributes = (;
        label_scatter = (;
            markersize = 20,
            marker = '↑',
            color = :black,
            rotation = rand(64) .* 2π,
        )
    ),
)

# Marker size change
plot_topoplot(
    topo_array[:, 50, 1];
    positions = topo_positions,
    axis = (; xlabel = "Time [50 ms]"),
    topo_attributes = (;
        label_scatter = (; markersize = rand(64) .* 2π, marker = :circle, color = :black)
    ),
)

# # Configurations of Topoplot

# ```@docs
# plot_topoplot
# ```

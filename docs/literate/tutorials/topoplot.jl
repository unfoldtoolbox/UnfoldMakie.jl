# # [Topoplot](@id topo_vis)
# **Topoplot** (aka topography plot) is a plot type for visualisation of EEG activity in a specific time stemp or time interval. 
# It can fully represent channel and channel location dimensions using contour lines.

# The topoplot is a 2D projection and interpolation of the 3D distributed sensor activity. The name stems from physical geography, but instead of height, the contour lines represent voltage levels. 

# # Setup
# Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using DataFrames

# Data loading

dat, positions = TopoPlots.example_data()

# The size of `data` is 64×400×3. This means:
# - 64 channels;
# - 400 timepoints in range from -0.3 to 0.5 mseconds;
# - Estimates of 3 averaging functions. Instead of displaying the EEG data for all subjects, here we aggregate the data using (1) mean, (2) standard deviation and (3) p-value within t-tests.

# While `position` consist of 64 x and y coordinates of each channels on a scalp. 


# # Plot Topoplots

# Here we select a time point in 340 msec and the mean estimate. 
plot_topoplot(dat[:, 340, 1]; positions = positions[1:4])

df = DataFrame(:estimate => dat[:, 340, 1])
plot_topoplot(df; positions = positions)


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
f = Figure(size = (500, 500))
labs4 = ["O1", "F2", "F3", "P4"]
plot_topoplot!(
    f[1, 1],
    dat[1:4, 340, 1];
    positions = positions[1:4],
    visual = (; label_scatter = false),
    labels = labs4,
    axis = (; title = "no channel scatter"),
)

plot_topoplot!(
    f[1, 2],
    dat[1:4, 340, 1];
    positions = positions[1:4],
    visual = (; label_text = true, label_scatter = (markersize = 15, strokewidth = 2)),
    labels = labs4,
    axis = (; title = "channel scatter with text"),
    mapping = (; labels = labs4),
)
f

# # Configurations of Topoplot

# ```@docs
# plot_topoplot
# ```

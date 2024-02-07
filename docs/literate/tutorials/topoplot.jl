# # Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using DataFrames

# # Plot Topoplots

# ## Data loading

data, positions = TopoPlots.example_data()

# Here we select a time point (340 msec) and the first entry of dimension 3 (the mean estimate, the others are p-value and std).
plot_topoplot(data[:, 340, 1]; positions = positions)

df = DataFrame(:estimate => data[:, 340, 1])
plot_topoplot(df; positions = positions)


# ## Setting Sensor Positions

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

cfgDefault = UnfoldMakie.PlotConfig()
cfgDefault.mapping.y

# # Labelling
#=
`label_text` draws labels next to their positions.
Example: `plot_topoplot(...; visual=(; label_text=true))`

`label_scatter (boolean)` draws the markers at the given positions.

Example: `plot_topoplot(...; visual=(; label_scatter=true))`
=#

plot_topoplot(
    data[1:4, 340, 1];
    visual = (; label_scatter = false),
    labels = ["O1", "F2", "F3", "P4"],
)

# # Configurations of Topoplot

# ```@docs
# plot_topoplot
# ```

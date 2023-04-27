# [Topo Plot Visualization](@id tp_vis)

Here we discuss topo plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
```

## Plot Topo Plots

### Providing the Data

```@example main
data, positions = TopoPlots.example_data()
```
We select one datapoint, and the first enry of dimension 3 (the mean estimate, the others are p-value and std)

```@example main
plot_topoplot(data[:,340,1];positions=positions)
```

```@example main
using DataFrames
df = DataFrame(:estimate=>data[:,340,1])
plot_topoplot(df;positions=positions)
```

### Giving the Positions

Since the topo plot needs the positions of the sensors they have to be put into the drawing function. But there are multiple options (In order of prioritization):

- Giving the positions directly: `plot_topoplot(...; positions=[...])`
- Giving the labels of the sensors: `plot_topoplot(...; labels=[...])`

To get the positions from the labels we use a [database](https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv).

## Column Mappings for Topo Plots

When using topo plots with a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

For more informations about mapping values look into the [Mapping Data](@ref config_mapping) section of the documentation.

While there are multiple default values, that are checked in that order if they exist in the `DataFrame`, a custom name might need to be choosen for:

Note that only one of `positions` or `labels` have to be set to draw a topo plot. If both are set, positions takes precedence, labels might be used for labelling electrodes in TopoPlots.jl

### (...,mapping=(;))

`:y` plotting function looks in the default columns of mapping
```@example main 
cfgDefault = UnfoldMakie.PlotConfig()
cfgDefault.mapping.y
```
`positions`
```@example main 
cfgDefault.mapping.positions #hide
```

`labels`
```@example main
cfgDefault.mapping.labels #hide
```


### label_text (boolean)
Indicates whether label should drawn next to their position.
Obviously the labels have to be provided: `plot_topoplot(...; labels=[...])`

`plot_topoplot(...;visual=(;label_text=true))`

### label_scatter (boolean)
Indicates whether the dots should be drawn at the given positions.

`plot_topoplot(...;visual=(;label_scatter=true))`


```@example main
data, positions = TopoPlots.example_data()
plot_topoplot(data[1:4,340,1];visual=(;label_scatter = false),  labels=["O1", "F2", "F3", "P4"])
```

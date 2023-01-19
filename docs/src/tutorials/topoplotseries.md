# [Topo Plot SeriesVisualization](@id tpseries_vis)


## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
```
To visualize topo plots we use the `TopoPlots` module.


## Plot Topo Plots Series

### Giving the Data

In case you do not already have data, you can get example data from the `TopoPlots` module. 
You can do it like this:
```@example main
data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(data[:,:,1],string.(1:length(positions)))
df.positions = positions[parse.(Int,df.label)]
```

```@example main
Δbin = 40
plot_topoplotseries(df,Δbin;setMappingValues=(topodata=:erp,),setVisualValues=(label_text = false,)) # for some reason text doesnt work right now...

```
At this point you can detail changes you want to make to the visualization through the plot config. 


### Giving the Positions
See the topoplots tutorial for details

## Column Mappings for Topo Plots

When using topo plots with a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

For more informations about mapping values look into the [Mapping Data](@ref config_mapping) section of the documentation.

While there are multiple default values, that are checked in that order if they exist in the `DataFrame`, a custom name might need to be choosen for:

Note that only one of `topoPositions`, `topoLabels` , or `topoChannels` have to be set to draw a topo plot. If multiple are set, they will be prioritized in that order.

### topodata
Default is `(:topodata, :data, :y, :estimate)`.

### topoPositions (See note above)
Default is `(:pos, :positions, :position, :topoPositions, :x, :nothing)`.

### topoLabels (See note above)
Default is `(:labels, :label, :topoLabels, :sensor, :nothing)`.

### topoChannels (See note above)
Default is `(:channels, :channel, :topoChannel, :nothing)`.


## Configurations for Topo Plots

Instead of extra settings, topo plots only feature a few settings that can be changed in the visual settings using `plot_topoplotseries(...;setVisualValues(<name>=<value>,...)`.

For more general options look into the `Plot Configuration` section of the documentation.

### label_text (boolean)
Indicates whether label should drawn next to their position.
The labels have to be given into the function seperately:
- For `TopoPlots` data use: `plot_topoplot(...; labels=[...])`
- For a `DataFrame` give a valid column name of a column with the labels (see above for more information on column mapping)

Default is `true`.

### label_scatter (boolean)
Indicates whether the dots should be drawn at the given positions.

Default is `true`.

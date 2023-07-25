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
## Plot Topo Plots Series

### Giving the Data

In case you do not already have data, you can get example data from the `TopoPlots` module. 
You can do it like this:
```@example main
data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(data[:,:,1], string.(1:length(positions)));
nothing #hide
```

```@example main
Δbin = 80
plot_topoplotseries(df, Δbin; positions = positions)
```


### Positions
You can give either positions, or labels. If both are provided, positions have priority

### plot_toposeries(...;mapping=(;key=value))
`mapping=(:y=(:estimate,:yhat,:y))`

### visual=(;)
`label_text` (boolean, false) Indicates whether label should drawn next to their position.
The labels have to be given into the function seperately:
!!! important
    currently bugged

`label_scatter` (boolean, true) - Indicates whether the dots should be drawn at the given positions.


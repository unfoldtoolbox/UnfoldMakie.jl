# [Topoplot Series Visualization](@id tpseries_vis)


## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using Statistics
```
## Plot Topoplot Series

### Example data

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
### Arguments usage

- `f::Union{GridPosition, GridLayout, Figure}`: Figure, GridLayout or GridPosition that the plot should be drawn into.
- `data::DataFrame`: DataFrame with data, needs a `time` column.
- `Δbin::Real`: A number for how large one time bin should be. Δbin is in units of the `data.time` column.

### Key arguments
- `combinefun` (default: `mean`) - specify how the samples within `Δbin` are summarised.
    possible functons: `mean`, `median`, `std`. 
- `rasterize_heatmaps` (default: `true`) - enforce rasterization of the plot heatmap when saving in svg format.
    This has the benefit that all lines/points are vectors, except the interpolated heatmap. 
    This is typically what you want, otherwise you get ~500x500 vectors per topoplot, which makes everything super slow.
- `col_labels`, `row_labels` - shows column and row labels. 
- `labels` (default: `nothing`) - channel labels.
- `positions` (default: `nothing`) - channel positions.

Disabling colorbar:

```@example main
plot_topoplotseries(df, Δbin; positions=positions, layout = (; use_colorbar=false))
```

### Aggregationg functions
In this example `combinefun` is specified by `mean`, `median` and `std`. 

```@example main
f = Figure()
plot_topoplotseries!(f[1, 1], df, Δbin; positions = positions, combinefun = mean)
plot_topoplotseries!(f[2, 1], df, Δbin; positions = positions, combinefun = median)
plot_topoplotseries!(f[3, 1], df, Δbin; positions = positions, combinefun = std)
f
```

### Positions
You can give either positions, or labels. If both are provided, positions have priority

### plot_toposeries(...; mapping=(; key=value))
`mapping=(: y=(:estimate, :yhat, :y))`


### visual=(;)
- `label_text` (boolean, false) Indicates whether label should drawn next to their position.
The labels have to be given into the function seperately:
!!! important
    currently bugged

- `label_scatter` (boolean, true) - Indicates whether the dots should be drawn at the given positions.


## [General Topo Plot Visualization](@id tp_vis)

### Include used modules
The following modules are necessary for following this tutorial:
```
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
using TopoPlots
```
To visualize topo plots we use the `TopoPlots` module.

### Data
In case you do not already have data, you can get example data from the `TopoPlots` module. 
You can do it like this:
```
data, positions = TopoPlots.example_data()
```

We want to use further pre-processing before visualizing the topo plot.
Let us first define some axis settings.
```
axisSettings = (topspinevisible=false,rightspinevisible=false,bottomspinevisible=false,leftspinevisible=false,xgridvisible=false,ygridvisible=false,xticklabelsvisible=false,yticklabelsvisible=false, xticksvisible=false, yticksvisible=false)
```
Some further definitions.
```
f = Figure()

labels = ["s$i" for i in 1:size(data, 1)]
f, ax, h = eeg_topoplot(data[:, 340, 1], labels; label_text=false,positions=positions, axis=axisSettings)
axis = Axis(f, bbox = BBox(100, 0, 0, 100); axisSettings...)
```

### Plot Topo Plots

At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

This is how you finally plot the topo plot.
```
draw = eeg_topoplot!(axis, zeros(64), labels; label_text=falsepositions=positions)

# for displaying
f
```

## [Visualization Options for Topo Plot](@id o_tp_vis)

## Plot Config?

## TODO: !
- any config options?
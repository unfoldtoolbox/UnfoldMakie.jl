## [General Topo Plot Visualization](@id tp_vis)

### Include used modules
The following modules are necessary for following this tutorial:
```@example main
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
```@example main
data, positions = TopoPlots.example_data()
```

### Configurations for Topo Plots
Here we look into possible options for configuring the topo plot visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 

Let us first define some axis settings.
```@example main
axisSettings = (topspinevisible=false,rightspinevisible=false,bottomspinevisible=false,leftspinevisible=false,xgridvisible=false,ygridvisible=false,xticklabelsvisible=false,yticklabelsvisible=false, xticksvisible=false, yticksvisible=false)
```
Now we can visualize the topo plot.
```@example main
f = Figure()

labels = ["s$i" for i in 1:size(data, 1)]
f, ax, h = eeg_topoplot(data[:, 340, 1], labels; label_text=false,positions=positions, axis=axisSettings)
axis = Axis(f, bbox = BBox(100, 0, 0, 100); axisSettings...)


draw = eeg_topoplot!(axis, zeros(64), labels; label_text=falsepositions=positions)

# for displaying
f
```


## TODO: MORE CONFIG DETAILS ONCE FINISHED
- check whether order works
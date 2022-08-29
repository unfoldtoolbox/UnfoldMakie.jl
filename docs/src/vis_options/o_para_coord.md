## [Visualization Options for Parallel Coordinates Plot](@id o_pcp_vis)


##   REMOVED FROM para_coord.md
### Configuration for PCP
Here we look into possible options for configuring the PCP visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
```
f = Figure()

data = effects(Dict(:category=>["face", "car"], :condition=>["intact"]), mres)

paraConfig = PlotConfig(:paracoord)

plot_paraCoord(data, paraConfig; channels=[1,7,6])
```
Note that you may need the names when setting mapping values to the data you use.

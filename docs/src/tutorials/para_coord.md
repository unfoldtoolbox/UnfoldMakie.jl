## [Parallel Coordinates Plot](@id pcp_vis)

Here we discuss parallel coordinates plot (PCP) visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

### Include used Modules
The following modules are necessary for following this tutorial:
```
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
using DataFramesMeta
```

Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

### Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

Use the test data of `erpcore-N170.jld2`.

We filter the data to make it more clearly represented:
```
results_plot = @subset(results_onesubject,:channel .<=6)
```

### Plot PCP Plots

The following code will result in the default configuration. 
```
paraConfig = PlotConfig(:paracoord)
```
If there are no columns named `category` or `yhat` we have to give the correct names. With this test data it has to be given:
```
paraConfig.setMappingValues(category=:coefname,yhat=:estimate)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

This is how you finally plot the PCP.
```
plot_paraCoord(results_plot, paraConfig; channels=[5,3,2])
```

## [Visualization Options for Parallel Coordinates Plot](@id o_pcp_vis)


##   REMOVED FROM para_coord.md
### Configuration for PCP
Here we look into possible options for configuring the PCP visualization.

```
f = Figure()

data = effects(Dict(:category=>["face", "car"], :condition=>["intact"]), mres)

paraConfig = PlotConfig(:paracoord)

plot_paraCoord(data, paraConfig; channels=[1,7,6])
```
Note that you may need the names when setting mapping values to the data you use.


## TODO: USED MODULES, DATA?
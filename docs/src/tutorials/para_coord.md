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
If there are no columns named `category`,`y`,`channel` and `time` we have to give the correct names. Though y has some alternative default values, it might be safer to set it directly. With this test data we give:
```
paraConfig.setMappingValues(category=:coefname, y=:estimate)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

We choose to put the legend at the bottom instead of to the right
```
paraConfig.setLayoutValues(legendPosition=:bottom)
```

This is how you finally plot the PCP.
```
plot_paraCoord(results_plot, paraConfig; channels=[5,3,2])
```

![Default PCP](../images/para_coord_default.png)


### Configuration for PCP

Here we look into possible options for configuring the PCP visualization.
The options for configuring the visualization mentioned here are specific for PCPs.
For more general options look into the `Plot Configuration` section of the documentation.
This is the list of unique configuration (extraData):
- ...


...

```
f = Figure()

data = effects(Dict(:category=>["face", "car"], :condition=>["intact"]), mres)

paraConfig = PlotConfig(:paracoord)

plot_paraCoord(data, paraConfig; channels=[1,7,6])
```
Note that you may need the names when setting mapping values to the data you use.


## TODO: USED MODULES, DATA?
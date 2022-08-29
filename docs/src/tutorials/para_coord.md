## [General Parallel Coordinates Plot](@id pcp_vis)

Here we discuss general parallel coordinates plot (PCP) visualization. 
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
[Here](@ref o_pcp_vis) we look into possible options for configuring the designmatrix visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 

This is how you finally plot the PCP.
```
plot_paraCoord(results_plot, paraConfig; channels=[5,3,2])
```

## TODO: USED MODULES, DATA?
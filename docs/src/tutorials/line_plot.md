## [General Line Plot Visualization](@id lp_vis)

Here we discuss general line plot visualization. 
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
results_plot = @subset(results_onesubject,:channel .==3)
```

### Plot Line Plots

The following code will result in the default configuration. 
```
cLine = PlotConfig(:lineplot)
```
[Here](@ref o_lp_vis) we look into possible options for configuring the line plot visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 

This is how you finally plot the line plot.
```
plot_line(results_plot, cLine)
```
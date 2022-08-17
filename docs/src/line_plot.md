## [General Line Plot Visualization](@id lp_vis)

Here we discuss general line plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

### Include used Modules
The following modules are necessary:
```@example main
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
```@example main
results_plot = @subset(results_onesubject,:coefname .== "(Intercept)",:channel .<5)
```


### Configurations for Line Plots
```@example main
cLine = PlotConfig(:lineplot)
cLine.setExtraValues(showLegend=true,
    legendPosition=:right,
    categoricalColor=false,
    categoricalGroup=true)
cLine.setMappingValues(color=:channel, group=:channel)
cLine.setLegendValues(nbanks=1)
```

### Plot Line Plots
This is how you finally plot the line plot.
```@example main
plot_line(results_plot, cLine)
```

## TODO: MORE CONFIG DETAILS ONCE FINISHED

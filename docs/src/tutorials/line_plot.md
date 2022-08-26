## [General Line Plot Visualization](@id lp_vis)

Here we discuss general line plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

### Include used Modules
The following modules are necessary for following this tutorial:
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

### Configuration for Line Plots
Here we look into possible options for configuring the line plot visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
```@example main
cLine.setExtraValues(showLegend=true,
    categoricalColor=false,
    categoricalGroup=false)
cLine.setMappingValues(color=:coefname, group=:coefname)
cLine.setLegendValues(nbanks=2)
cLine.setLayoutValues(legendPosition=:bottom)
plot_line(results_plot, cLine)
```
Note that you may need to the names when setting mapping values to the data you use.

### Configuration for Line Plots with STD Error
In case you add `stderror=true` when setting extra values, you get a visualization that displays them.
```@example main
cLine = PlotConfig(:lineplot)
cLine.setExtraValues(
    categoricalColor=false,
    categoricalGroup=false,
    stderror=true)
cLine.setMappingValues(color=:coefname, group=:coefname)
cLine.setLegendValues(nbanks=2)
cLine.setLayoutValues(legendPosition=:bottom)
plot_line(results_plot, cLine)
```
Note that you may need to the names when setting mapping values to the data you use.

### Configuration for Line Plots with p-values
In case you have `pvalue` defined in the extra values, it will be displayed in the visualization.
In the following you can soo a simple definition
```@example main
cLine = PlotConfig(:lineplot)

pvals = DataFrame(
		from=[0.1,0.3],
		to=[0.5,0.7],
		coefname=["(Intercept)","category: face"] # if coefname not specified, line should be black
	)

cLine.setExtraValues(
    categoricalColor=false,
    categoricalGroup=false,
    pvalue=pvals)
cLine.setMappingValues(color=:coefname, group=:coefname)
cLine.setLayoutValues(legendPosition=:bottom)
cLine.setLegendValues(nbanks=2)
plot_line(results_plot, cLine)
```
Note that you may need to the names when setting mapping values to the data you use.

### Plot Line Plots
This is how you finally plot the line plot.
```@example main
plot_line(results_plot, cLine)
```

## TODO: MORE CONFIG DETAILS ONCE FINISHED

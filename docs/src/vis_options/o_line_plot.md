## [Visualization Options for Line Plot](@id o_lp_vis)


##   REMOVED FROM line_plot.md
### Configuration for Line Plots
Here we look into possible options for configuring the line plot visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
```
cLine = PlotConfig(:lineplot)
cLine.setExtraValues(showLegend=true,
    categoricalColor=false,
    categoricalGroup=false)
cLine.setMappingValues(color=:coefname, group=:coefname)
cLine.setLegendValues(nbanks=2)
cLine.setLayoutValues(legendPosition=:bottom)
```
```
plot_line(results_plot, cLine)
```
Note that you may need to the names when setting mapping values to the data you use.

### Configuration for Line Plots with STD Error
In case you add `stderror=true` when setting extra values, you get a visualization that displays them.
```
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
```
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

# [Line Plot Visualization](@id lp_vis)

Here we discuss line plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
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

## Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

Use the test data of `erpcore-N170.jld2`.

We filter the data to make it more clearly represented:
```
results_plot = @subset(results_onesubject,:channel .==3)
```

## Plot Line Plots

The following code will result in the default configuration. 
```
cLine = PlotConfig(:line)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

This is how you plot the line plot.
```
cLine.plot(results_plot)
```

![Default Line Plot](../images/line_plot_default.png)

## Column Mappings for Line Plots

Since line plots use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

For more infos about mapping values look into the [Mapping Data](@ref config_mapping) section of the documentation.

While there are multiple default values, that are checked in order if they exist in the `DataFrame`, a custom name might need to be choosen for:

### x
Default is `(:x, :time)`.

### y
Default is `(:y, :estimate, :yhat)`.

### color (Optional)
Default is `(:color, :coefname)`.


## Configuration for Line Plots

Here we look into possible options for configuring the line plot visualization using `config.setExtraValues(<name>=<value>,...)`.
By calling the `config.plot(...)` function on a line plot the function `plot_lines(...)` is executed.

For more general options look into the `Plot Configuration` section of the documentation.
This is the list of unique configuration (extraData):
- categoricalColor (boolean)
- categoricalGroup (boolean)
- pvalue (array)
- stderror (boolean)

Using some general configurations we can pretty up the default visualization. Here we use the following configuration:
```
cLine.setExtraValues(showLegend=true,
    categoricalColor=false,
    categoricalGroup=false)
cLine.setMappingValues(color=:coefname, group=:coefname)
cLine.setLegendValues(nbanks=2)
cLine.setLayoutValues(legendPosition=:bottom)
```

![Pretty Line Plot](../images/line_plot_pretty.png)

In the following we will use this "pretty" line plot as a basis for looking into configuration options.


### categoricalColor (boolean)
Indicates whether the column referenced in mappingData.color should be used nonnumerically.
Default is `true`.


### categoricalGroup (boolean)
Indicates whether the column referenced in mappingData.group should be used nonnumerically.
Default is `true`.


### pvalue (array)
Is an array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values. 
Default is `[]` (an empty array).

Shown below is an example in which `pvalue` are given:
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
cLine.plot(results_plot)
```

![Pretty Line Plot](../images/line_plot_p-val.png)


### stderror (boolean)
Indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 
Default is `false`.

Shown below is an example where `stderror=true`:
```
cLine.setExtraValues(
    categoricalColor=false,
    categoricalGroup=false,
    stderror=true)
cLine.setMappingValues(color=:coefname, group=:coefname)
cLine.setLegendValues(nbanks=2)
cLine.setLayoutValues(legendPosition=:bottom)
```

![Pretty Line Plot](../images/line_plot_std.png)
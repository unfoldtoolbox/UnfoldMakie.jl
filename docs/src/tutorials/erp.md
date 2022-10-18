# [Line Plot Visualization](@id lp_vis)

Here we discuss line plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using DataFramesMeta
```
Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

## Data
In case you want different data, look at the [Load Data](@ref test_data) section. 

```@example main
results_plot = @subset(UnfoldMakie.example_data(),:channel .== 32);
first(results_plot ,3)
```

## Plot Line Plots

The following code will result in the default configuration. 
```@example main
plot_erp(results_plot)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 


## Column Mappings for Line Plots

Since line plots use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

For more informations about mapping values look into the [Mapping Data](@ref config_mapping) section of the documentation.

While there are multiple default values, that are checked in that order if they exist in the `DataFrame`, a custom name might need to be choosen for:

### x
Default is `(:x, :time)`.

### y
Default is `(:y, :estimate, :yhat)`.

### color
Default is `(:color, :coefname)`.


## Configuration for Line Plots

Here we look into possible options for configuring the line plot visualization using `plot_erp(...;setExtraValues=(<name>=<value>,...)`.

For more general options look into the `Plot Configuration` section of the documentation.
This is the list of unique configuration (extraData):
- categoricalColor (boolean)
- categoricalGroup (boolean)
- pvalue (array)
- stderror (boolean)

Using some general configurations we can pretty up the default visualization. Here we use the following configuration:
```@example main
plot_erp(results_plot;
    setExtraValues=(showLegend=true,
                    categoricalColor=false,
                    categoricalGroup=false),
    setMappingValues = (color=:coefname, group=:coefname,),
    setLegendValues  = (nbanks=2,),
    setLayoutValues  = (legendPosition=:bottom,))
```



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
```@example main
pvals = DataFrame(
		from=[0.1,0.3],
		to=[0.5,0.7],
		coefname=["A","B"] # if coefname not specified, line should be black
	)

plot_erp(results_plot;
    setExtraValues= (
        categoricalColor=false,
        categoricalGroup=false,
        pvalue=pvals),
    setMappingValues = (color=:coefname, group=:coefname,),
    setLayoutValues = (legendPosition=:bottom,),
    setLegendValues = (nbanks=2,),)

```


### stderror (boolean)
Indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 
Default is `false`.

Shown below is an example where `stderror=true`:
```@example main

results_plot.se_low = results_plot.estimate .- 0.05
results_plot.se_high = results_plot.estimate .+ 0.05
plot_erp(results_plot;
    setExtraValues= (
        categoricalColor=false,
        categoricalGroup=false,
        stderror=true),
    setMappingValues = (color=:coefname, group=:coefname,),
    setLayoutValues = (legendPosition=:bottom,),
    setLegendValues = (nbanks=2,),)
```


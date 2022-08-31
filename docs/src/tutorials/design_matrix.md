## [Designmatrix Visualization](@id dm_vis)

Here we discuss designmatrix visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct) section. 

### Include used modules
The following modules are necessary for following this tutorial:
```
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
```

### Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

When you followed the tutorial, using test data of the `Unfold` module, use the following code for further pre-processing:
```
ufMass = UnfoldLinearModel(Dict(Any=>(f,-0.4:1/50:.8)))
designmatrix(ufMass, evts)
```
When you followed the tutorial, using test data of the file `erpcore-N170.jld2`, use the following code:
```
designmatrix(mres)
```

## Plot Designmatrices

The following code will result in the default configuration. 
```
cDesign = PlotConfig(:designmatrix)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

This is how you finally plot the designmatrix, when using data of the `Unfold` module.
```
plot_design(designmatrix(ufMass, evts), cDesign)
```
This is how you finally plot the designmatrix, when using data of the `erpcore-N170.jld2` file.
```
plot_design(designmatrix(mres), cDesign)
```

![Default Designmatrix](../images/designmatrix_default.png)


## Configurations for Designmatrices

Here we look into possible options for configuring the designmatrix visualization.
The options for configuring the visualization mentioned here are specific for designmatrices.
For more general options look into the `Plot Configuration` section of the documentation.
This is the list of unique configuration (extraData):
- sortData (boolean)
- standardizeData (boolean)
- xTicks (number)


### sortData (boolean)

Indicating whether the data is sorted; using sortslices() of Base Julia. 
Default is `false`.

In order to make the designmatrix easier to read, you may want to sort it.
The following configuration achieves this:
```
cDesign.setExtraValues(sortData=true)
```

![Sorted Designmatrix](../images/designmatrix_sorted.png)

### standardizeData (boolean)
Indicating whether the data is standardized by pointwise division of the data with its sampled standard deviation. 
Default is `true`.

If you don't want the data you use to be standardized, set this value to `false`, as seen below.
```
cDesign.setExtraValues(standardizeData=false)
```


### xTicks (number)
Indicating the number of labels on the x-axis. Behavior if specified in configuration:
- xTicks = 0: no labels are placed.
- xTicks = 1: first possible label is placed.
- xTicks = 2: first and last possible labels are placed.
- 2 < xTicks < number of labels: xTicks-2 labels are placed between the first and last.
- xTicks ≥ number of labels: all labels are placed.

This is how you apply the configuration:
```
cBugDesign.setExtraValues(xTicks=2)
```
In this case it was set to two labels on the x-axis.



## TODO: INSTRUCTIONS
- timeexpanded vs not -> mention some extra data multiple times or restructure?
- add further extraData?
- images for all options?
Potentially missing content: 
https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev/plot_design/#Plot-Designmatrix

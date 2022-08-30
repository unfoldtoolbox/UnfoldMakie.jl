## [General Designmatrix Visualization](@id dm_vis)

Here we discuss general designmatrix visualization. 
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


## Plot Timeexpanded Designmatrices

In the code below, data of the `Unfold` module was used.
To display a timeexpanded designmatrix we add the following code:
```
bfDict = Dict(Any=>(f,basisfunction))
ufCont = UnfoldLinearModelContinuousTime(bfDict)
```
The following code will result in the default configuration.
```
cBugDesign = PlotConfig(:designmatrix)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

This is how you finally plot the timeexpanded designmatrix.
```
plot_design(designmatrix!(ufCont, evts), cBugDesign)
```
Note that without further adjustments in the configuration, you may experience cluttering of labels.


## Visualization Options for Designmatrix

##   REMOVED FROM design_matrix.md
### Configurations for Designmatrices
Here we look into possible options for configuring the designmatrix visualization.

The following code will result in the default configuration. 
```
cDesign = PlotConfig(:designmatrix)
```
...---Some configurations are displayed below. 
In case you want to display less labels on a specific axis, you can execute the following code:
```
cDesign.setExtraValues(xTicks=5, sortData=true)
```
In this example, the number of labels on the x-axis is set to 2.---...

TODO more examples



### Configurations for Designmatrices
Here we look into possible options for configuring the designmatrix visualization.

The following code will result in the default configuration.
```
cBugDesign = PlotConfig(:designmatrix)
```

An especially useful configuration is limiting the number of labels on the x-axis. 
In the following case to 12.
```
cBugDesign.setExtraValues(xTicks=12)
```


## TODO: INSTRUCTIONS
Potentially missing content: 
https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev/plot_design/#Plot-Designmatrix

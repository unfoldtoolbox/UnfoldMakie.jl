## [General Designmatrix Visualization](@id dm_vis)

Here we discuss general designmatrix visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct). 

### Include used modules
The following modules are necessary:
```@example main
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
```

### Load Data
Within the scope of the documentation we use test data of the Unfold module. 
In the following we load the data. 
```@example main
include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data

data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA

ufMass = UnfoldLinearModel(Dict(Any=>(f,-0.4:1/50:.8)))
designmatrix(ufMass, evts)
```

## For Designmatrices

### Configurations for the Designmatrix
Here we look into possible options for configuring the designmatrix visualization.
For more information on plot configurations in general, look at this section of the [documentation](@ref TODO). 
The following code will result in the default configuration. 
```@example main
cDesign = PlotConfig(:designmatrix)
```
...---Some configurations are displayed below. 
In case you want to display less labels on a specific axis, you can execute the following code:
```@example main
cDesign.setExtraValues(xTicks=2)
```
In this example, the number of labels on the x-axis is set to 2.---...

TODO more examples

### Plot the Designmatrix
This is how you finally plot the designmatrix.
```@example main
plot_design(designmatrix(ufMass, evts), cDesign;sort=true)
```
You can omit `sort=true` to get an unsorted designmatrix.


## For Timeexpanded Designmatrices

### Additional Adjustments
To display a timeexpanded designmatrix we add the following code:
```@example main
bfDict = Dict(Any=>(f,basisfunction))
ufCont = UnfoldLinearModelContinuousTime(bfDict)
```

### Configurations for the Designmatrix
Here we look into possible options for configuring the designmatrix visualization.
For more information on plot configurations in general, look at this section of the [documentation](@ref TODO). 
The following code will result in the default configuration.
```@example main
cBugDesign = PlotConfig(:designmatrix)
```

An especially useful configuration is limiting the number of labels on the x-axis. 
In the following case to 12.
```@example main
cBugDesign.setExtraValues(xTicks=12)
```

### Plot the Timeexpanded Designmatrix
This is how you finally plot the timeexpanded designmatrix.
```@example main
plot_design(designmatrix!(ufCont, evts), cBugDesign)
```



## TODO INSTRUCTIONS
Potentially missing content: 
https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev/plot_design/#Plot-Designmatrix

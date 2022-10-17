# [Designmatrix Visualization](@id dm_vis)

Here we discuss designmatrix visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct) section. 

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
```

## Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 
```@example main
# load and generate a simulated Unfold Design

include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data

data, evts = loadtestdata("test_case_3b");
f  = @formula 0~1+conditionA+continuousA

# generate ModelStruct
ufMass = UnfoldLinearModel(Dict(Any=>(f,-0.4:1/50:.8))) 
# generate designmatrix
designmatrix!(ufMass, evts)
```


## Plot Designmatrices

The following code will result in the default configuration. 
```@example main
plot_designmatrix(designmatrix(ufMass))
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 



![Default Designmatrix](../images/designmatrix_default.png)

## Column Mappings for Designmatrices

Since designmatrix uses an `Unfold.DesignMatrix` as an input, the library does not need any informations about the mapping.

## Configurations for Designmatrices

Here we look into possible options for configuring the designmatrix visualization using `plot_designmatrix(...;setExtraValues=(<name>=<value>,...)`.

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
plot_designmatrix(designmatrix(ufMass);setExtraValues=(sortData=true,))
```

![Sorted Designmatrix](../images/designmatrix_sorted.png)

### standardizeData (boolean)
Indicating whether the data is standardized, mapping the values between 0 and 1. 
Default is `true`.


### xTicks (number)
Indicating the number of labels on the x-axis. Behavior if specified in configuration:
- xTicks = 0: no labels are placed.
- xTicks = 1: first possible label is placed.
- xTicks = 2: first and last possible labels are placed.
- 2 < xTicks < number of labels: xTicks-2 labels are placed between the first and last.
- xTicks ≥ number of labels: all labels are placed.
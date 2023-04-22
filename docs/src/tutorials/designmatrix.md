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
include("../../example_data.jl")
uf = example_data("UnfoldLinearModel")

```


## Plot Designmatrices

The following code will result in the default configuration. 
```@example main
plot_designmatrix(designmatrix(uf))
```

# `plot_designmatrix(...;extra=(<name>=<value>,...)`.

- sortData (boolean,false)  - Indicating whether the data is sorted; using sortslices() of Base Julia. 


In order to make the designmatrix easier to read, you may want to sort it.
```
plot_designmatrix(designmatrix(uf);extra=(;sortData=true))
```

- standardizeData (boolean,false) - Indicating whether the data is standardized, mapping the values between 0 and 1. 


- xTicks (number,nothing)
Indicating the number of labels on the x-axis. Behavior if specified in configuration:
    - xTicks = 0: no labels are placed.
    - xTicks = 1: first possible label is placed.
    - xTicks = 2: first and last possible labels are placed.
    - 2 < xTicks < number of labels: xTicks-2 labels are placed between the first and last.
    - xTicks ≥ number of labels: all labels are placed.
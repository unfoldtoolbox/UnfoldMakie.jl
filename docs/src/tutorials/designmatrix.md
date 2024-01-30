# [Designmatrix Visualization](@id dm_vis)

Here we discuss design matrix visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct) section. 

## Package loading
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
```

## Data

```@example main
include("../../example_data.jl")
uf = example_data("UnfoldLinearModel")

```


## Plot Designmatrices

The following code will result in the default configuration. 
```@example main
plot_designmatrix(designmatrix(uf))
```

# kwargs `plot_designmatrix(...; ...)`.

- `sort_data` (bool, `true`): indicates whether the data is sorted; using sortslices() of Base Julia. 

To make the design matrix easier to read, you may want to sort it.

```@example main
plot_designmatrix(designmatrix(uf); sort_data=true)
```

- `standardize_data` (bool,`true`): indicates whether the data is standardized by pointwise division of the data with its sampled standard deviation.
- `sort_data` (bool, `true`): indicates whether the data is sorted; using sortslices() of Base Julia. 
- `xticks` (`nothing`): returns the number of labels on the x-axis. Behavior is set in the configuration:
    - xticks = 0: no labels are placed.
    - xticks = 1: first possible label is placed.
    - xticks = 2: first and last possible labels are placed.
    - 2 < xticks < `number of labels`: equally distribute the labels.
    - xticks ≥ `number of labels`: all labels are placed.

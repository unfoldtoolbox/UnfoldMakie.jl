# [Parallel Coordinates Plot](@id pcp_vis)
Here we discuss parallel coordinates plot (PCP) visualization. 

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
```

## Data

We use the test data of `erpcore-N170.jld2`.

```@example main
include("../../example_data.jl")
results_plot, positions = example_data();
```

## Plot PCPs

```@example main
plot_parallelcoordinates(results_plot, [5,3,2]; # this selects channel 5,3 & 2 
    mapping = (color = :coefname, y = :estimate))
```



!!! important
    the following is still outdated...
    
## Column Mappings for PCPs

Since PCPs use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

While there are multiple default values that are checked in that order if they exist in the `DataFrame`, a custom name might need to be choosen for:

### y
Default is `(:y, :estimate, :yhat)`.

### channel
Default is `:channel`.

### color
XXX Default is `:coef`.

### time
Default is `:time`.


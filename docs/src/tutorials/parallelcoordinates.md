# [Parallel Coordinates Plot](@id pcp_vis)

Here we discuss parallel coordinates plot (PCP) visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie

```

Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

## Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

Use the test data of `erpcore-N170.jld2`.

```@example main
results_plot = UnfoldMakie.example_data()
first(results_plot,6)
```

## Plot PCPs

The following code will result in the default configuration. 

If the column names of the `DataFrame` do not fit the default values we have to set the correct names. These are detailed further below.
```@example main
plot_parallelcoordinates(results_plot,[5,3,2];
    setMappingValues = (category=:coefname, y=:estimate),
    setLayoutValues = (legendPosition=:bottom,))# We choose to put the legend at the bottom instead of to the right:
```



## Column Mappings for PCPs

Since PCPs use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

For more informations about mapping values, look into the [Mapping Data](@ref config_mapping) section of the documentation.

While there are multiple default values that are checked in that order if they exist in the `DataFrame`, a custom name might need to be choosen for:

### y
Default is `(:y, :estimate, :yhat)`.

### channel
Default is `:channel`.

### category
Default is `:category`.

### time
Default is `:time`.

### Configuration for PCPs

Instead of extra settings, PCPs only feature a few variables that can be used to fix some problems with the visualization using `config.setExtraValues(<name>=<value>,...)`.
More on these variables and their use can be read in [Fix Parallel Coordinates Plot](@ref ht_fpcp).

By calling the `config.plot(...)` function on a PCP the function `plot_parallelcoordinates(...)` is executed.
For more general options look into the `Plot Configuration` section of the documentation.

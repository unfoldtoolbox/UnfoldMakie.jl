# [Parallel Coordinates Plot](@id pcp_vis)

Here we discuss parallel coordinates plot (PCP) visualization. 
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
results_plot = @subset(results_onesubject,:channel .<=6)
```

## Plot PCPs

The following code will result in the default configuration. 
```
cParacoord = PlotConfig(:paracoord)
```
If the column names of the `DataFrame` do not fit the default values we have to set the correct names. These are detailed further below.
```
cParacoord.setMappingValues(category=:coefname, y=:estimate)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are also detailed further below. 

We choose to put the legend at the bottom instead of to the right
```
cParacoord.setLayoutValues(legendPosition=:bottom)
```

This is how you plot the PCP.
```
cParacoord.plot(results_plot; channels=[5,3,2])
```

![Default PCP](../images/para_coord_default.png)

## Column Mappings for PCPs

Since PCPs use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

For more infos about mapping values look into the [Mapping Data](@ref config_mapping) section of the documentation.

While there are multiple default values, that are checked in that order if they exist in the `DataFrame`, a custom name might need to be choosen for:

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

By calling the `config.plot(...)` function on a PCP the function `plot_paraCoord(...)` is executed.
For more general options look into the `Plot Configuration` section of the documentation.

## Another PCP

When you followed the tutorial, using test data of the file `erpcore-N170.jld2`, the following code can create a parallel coordinate plot comparing face and car samples:

```
data = effects(Dict(:category=>["face", "car"], :condition=>["intact"]), mres)

cParacoord = PlotConfig(:paracoord)
cParacoord.setVisualValues(colormap = :RdBu)
cParacoord.setLayoutValues(legendPosition=:right)
cParacoord.setExtraValues(
    pc_aspect_ratio = 0.8,
    pc_right_padding = 15,
    pc_left_padding = 45,
    pc_top_padding = 50,
    pc_bottom_padding = 24,
    pc_tick_label_size = 15,
)

cParacoord.plot(data; channels=[1,7,6])
```

![Alternative PCP](../images/PCP_alt.png)
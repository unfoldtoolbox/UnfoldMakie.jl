# [Butterfly Plot Visualization](@id bfp_vis)

Here we discuss butterfly plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using UnfoldMakie
using Unfold
using CairoMakie
using DataFrames
```
Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

## Data

We filter the data to make it more clearly represented:
```@example main
include("../../example_data.jl")
df, pos = example_data("TopoPlots.jl")
first(df, 3)
```

## Plot Butterfly Plots

The default butterfly plot:
```@example main
plot_butterfly(df)
```

The butterfly plot with corresponding topoplot. You need to provide the channel positions.

```@example main
plot_butterfly(df; positions=pos)
```

You want to change size of topomarkers and size of topoplot:
```@example main
plot_butterfly(
    data;
    positions = pos,
    topomarkersize = 10,
    topoheigth = 0.4,
    topowidth = 0.4,
)
```

You want to add vline and hline:
```@example main
f = Figure()
plot_butterfly!(f, data; positions = pos)
hlines!(0, color = :gray, linewidth = 1)
vlines!(0, color = :gray, linewidth = 1)
f
```
You want to remove all decorations:
```@example main
plot_butterfly(
    data;
    positions = pos,
    layout = (;
        hidedecorations = (:label => true, :ticks => true, :ticklabels => true)
    ),
)
```

## Column Mappings for Butterfly Plots

Since butterfly plots use a `DataFrame` as input, the library needs to know the names of the columns used for plotting. You can set these mapping values by calling `plot_butterfly(...; mapping=(; :x=:time))`, that is, by specifying a `NamedTuple` (note the `;` right after the opening parentheses).

While there are several default values that will be checked in that order if they exist in the `DataFrame`, a custom name may need to be chosen:


### x
Default is `(:x, :time)`.

### y
Default is `(:y, :estimate, :yhat)`.

### labels
Default is `(:labels, :label, :topoLabels, :sensor, :nothing)`


## Configurations for Butterfly Plots

Here we look into possible options for configuring the butterfly plot visualization using `(...; <name>=<value>, ...)`.

## key values
- `butterfly` (bool, `true`): create a butterfly plot.
- `topolegend` (bool, `true`): show an inlay topoplot with corresponding electrodes.
- `topomarkersize` (Real, `10`): change the size of the markers, topoplot-inlay electrodes.
- `topowidth` (Real, `0.25`): change the size of the inlay topoplot width.
- `topoheigth` (Real, `0.25`): change the size of the inlay topoplot height.
- `topopositions_to_color` (function, ´x -> posToColorRomaO(x)´).


Since the configurations for ERP plots can be applied to butterfly plots as well.
[Here](@ref lp_vis) you can find the configurations for ERP plots.


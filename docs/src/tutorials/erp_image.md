## [ERP Image Visualization](@id erpi_vis)

Here we discuss butterfly plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

### Include used Modules
The following modules are necessary for following this tutorial:
```
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
using DataFramesMeta
using Random
```
Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).

Note that `Random` is used.

### Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

Use the test data of `erpcore-N170.jld2`.
Note that you do not need the pre-processing step detailed in that section.

### Plot ERP Images

The following code will result in the default configuration. 
```
erpConfig = PlotConfig(:erp)
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 

This is how you finally plot the ERP image.
```
plot_erp(dat_e[28,:,:], erpConfig)
```

## [Visualization Options for ERP Image](@id o_erpi_vis)

##   REMOVED FROM erp_image.md
### Configurations for ERP Images
Here we look into possible options for configuring the ERP image visualization.

```
erpConfig = PlotConfig(:erp)
erpConfig.setExtraValues(;ylims = (low = 3650, high = 8000),
	ylabel = "Sorted trials",
	meanPlot = true)
erpConfig.setColorbarValues(;label = "Voltage [µV]")
erpConfig.setVisualValues(;colormap = Reverse("RdBu"), colorrange = (-40, 40))
```

## TODO: MORE CONFIG DETAILS ONCE FINISHED
- is DataFramesMeta needed here?
- Link to config + more detail?
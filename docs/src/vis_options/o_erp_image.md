## [Visualization Options for ERP Image](@id o_erpi_vis)

##   REMOVED FROM erp_image.md
### Configurations for ERP Images
Here we look into possible options for configuring the ERP image visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
```
erpConfig = PlotConfig(:erp)
erpConfig.setExtraValues(;ylims = (low = 3650, high = 8000),
	ylabel = "Sorted trials",
	meanPlot = true)
erpConfig.setColorbarValues(;label = "Voltage [µV]")
erpConfig.setVisualValues(;colormap = Reverse("RdBu"), colorrange = (-40, 40))
```
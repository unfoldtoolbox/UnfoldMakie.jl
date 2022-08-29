## [Visualization Options for Designmatrix](@id o_dm_vis)

##   REMOVED FROM design_matrix.md
### Configurations for Designmatrices
Here we look into possible options for configuring the designmatrix visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
The following code will result in the default configuration. 
```
cDesign = PlotConfig(:designmatrix)
```
...---Some configurations are displayed below. 
In case you want to display less labels on a specific axis, you can execute the following code:
```
cDesign.setExtraValues(xTicks=5, sortData=true)
```
In this example, the number of labels on the x-axis is set to 2.---...

TODO more examples



### Configurations for Designmatrices
Here we look into possible options for configuring the designmatrix visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
The following code will result in the default configuration.
```
cBugDesign = PlotConfig(:designmatrix)
```

An especially useful configuration is limiting the number of labels on the x-axis. 
In the following case to 12.
```
cBugDesign.setExtraValues(xTicks=12)
```
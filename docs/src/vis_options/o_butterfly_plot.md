## [Visualization Options for Butterfly Plot](@id o_bfp_vis)


##   REMOVED FROM butterfly_plot_matrix.md
### Configurations for Butterfly Plots
Here we look into possible options for configuring the butterfly plot visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 
```
cButter = PlotConfig(:butterfly)
        
cButter.setExtraValues(categoricalColor=false,
    categoricalGroup=true,
    legendPosition=:right,
    border=false,
    topoLabel=:position)
    
# for testing add a column with labels
results_plot_butter.position = results_plot_butter[:, :channel] .|> c -> ("C" * string(c))
```

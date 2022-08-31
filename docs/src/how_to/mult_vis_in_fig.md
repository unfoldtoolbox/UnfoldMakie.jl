## [Include multiple Visualizations in one Figure](@id ht_mvf)

In this section we discuss how users are able to include multiple visualizations in a single figure.

By using the !-version of each plot and giving the plot functions grid positions instead of full figures, we can create Coordinated Multiple Views.

You start by creating a figure with Makie.Figure. 

`f = Figure()`

now each plot can be added to `f` via the `config.plot!()` function by putting in a grid position of `f`

```
f = Figure()
cButter = PlotConfig(:butterfly)
cLine = PlotConfig(:line)

cButter.setMappingValues(topoChannels=:channel)
cLine.setMappingValues(color=:channel)

cLine.plot!(f[1,1], results_plot_butter)
cButter.plot!(f[2, 1], results_plot_butter)

f
```

![Simple Coordinated Multiple Views](../images/two_plots.png)

By using the data from the tutorials we can create a big image with every plot (Code below).
With so many plots at once it's incentivised to set a fixed resolution in your figure to order the plots evenly.


![Coordinated Multiple Views](../images/every_plot.png)

```


```


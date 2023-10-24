# [Show out of Bounds Label](@id ht_soobl)

When visualizing a design matrix, it can happen that the labels on the y-axis get cut off to the left (especially if they are quite long). 
In the following, we will discuss a possible quick solution to this problem.

We start with the "label-limited" time-expanded designmatrix from the [corresponding Tutorial section](@ref dm_vis), which describes in detail how to generate it.

```@julia main
plot_designmatrix(designmatrix!(ufCont,evts), cDesign; xTicks=10, sortData=false)
```

#![Label Limited Timeexpanded Designmatrix](../images/designmatrix_te_12_labels.png)

While the plot automatically sets its height according to the labels, the labels are cut off on the left side.

A quick fix would be to place an empty plot to the left of the designmatrix.

By creating your own figure with Makie.Figure and then giving the designmatrix only a certain grid position, we get white space next to the plot.

The `plot!` function inside the plot config instance can take any grid position, and the figure `f` will contain the plot and enough white space next to it.

The exact numbers in the grid position can be guessed from the overlap ratio, or just tried.

```@julia main
f = Figure()
plot_design(f[1,2:6], designmatrix!(ufCont, evts), cDesign; setExtraValues=(xTicks=10, sortData=false))

f
```

#![Label Limited Timeexpanded Designmatrix](../images/label_fix.png)
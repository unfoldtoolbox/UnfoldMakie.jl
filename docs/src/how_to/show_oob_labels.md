# [Show out of Bounds Label](@id ht_soobl)

When visualizing a designmatrix it can happen that the labels on the y-axis get cut off towards the left (especially if they are quite long). 
In the following we discuss a possible quick fix for this problem.

Here we start off with the "label-limited" timeexpanded designmatrix from the [corresponding How To section](@ref ht_gen_te_designmatrix) that details how it can be generated.

```@julia main
plot_designmatrix(designmatrix!(ufCont,evts),cDesign;setExtraValues=(xTicks=10, sortData=false))
```

#![Label Limited Timeexpanded Designmatrix](../images/designmatrix_te_12_labels.png)

While the plot automatically sets it's height accoring to the labels, they are cut off on the left side.

A quick fix would be to place an empty plot to the left of the designmatrix.

By creating your own figure with Makie.Figure, and then only giving a certain grid position to the designmatrix we get white space next to the plot.

The `plot!` function inside the plot config instance can take any grid position, and the figure `f` will include plot and sufficient white space next to it.

The exact numbers in the grid position can be guessed from the ratio of the overlap, or just tried out.

```@julia main
f = Figure()
plot_design(f[1,2:6],designmatrix!(ufCont,evts),cDesign;setExtraValues=(xTicks=10, sortData=false))

f
```

#![Label Limited Timeexpanded Designmatrix](../images/label_fix.png)
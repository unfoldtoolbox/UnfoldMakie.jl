# [Hide Axis Spines and Decorations](@id ht_hide_deco)

This section discusses how users can efficiently hide axis spines and decorations in their plots.

While it's possible to hide these axis decorations by setting the axis settings with `axis=(;...)`, `Makie.Axis` provides multiple variables for different aspects of the plot. This means that removing all decorations is only possible by setting many variables each time.

Makie does provide methods like `hidespines!` and `hidedecorations!`, but the user may not have easy access to the axis their plot is drawn in.

Instead, these functions can be called by setting variables with `layout = (;)`:

```
... layout = (
    ...
    hidespines = (),
    hidedecorations = ()
)
```

Since these values reflect the input to the function, we can use an empty tuple to remove all decorations and spines, respectively

And using `hidespines = (:r, :t)` will remove the top and right borders.

For more information on the input of these functions refer to the [Makie dokumentation on Axis.](https://makie.juliaplots.org/v0.15.2/examples/layoutables/axis/#hiding_axis_spines_and_decorations)

Since some plots hide features by default, the hiding can be reverted by setting the variables to `nothing`

```
plot_xxx(...;layout=(;
    hidespines = nothing,
    hidedecorations = nothing
)
```


![Topoplot with all axis spines and decorations enabled](../images/spine_topo.png)


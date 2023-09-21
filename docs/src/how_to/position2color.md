# [Change Butterfly Channel Position Color](@id ht_p2c)

In this section we discuss how users are able change the position to colorscale of the legendtopo in the butterfly plot.

```@example main
using UnfoldMakie
using CairoMakie
using DataFramesMeta
using Colors
```

By default the plot looks like this:
```@example main
include("../../example_data.jl")
results, positions = example_data("TopoPlots.jl")
plot_butterfly(results; positions=positions)
```

We can switch the colorscale of the position-map, by giving a function that maps from a `(x,y)` tuple to a color. UnfoldMakie currently provides three different ones `pos2colorRGB` (same as MNE-Python), `pos2colorHSV` (HSV colorspace), `pos2colorRomaO`. Whereas `RGB` & `HSV` have the benefits of being 2D colormaps, `Roma0` has the benefit of being perceptualy uniform.


### Similar to MNE
```@example main
plot_butterfly(results; positions=positions, extra=(; topoPositionToColorFunction = pos -> UnfoldMakie.posToColorRGB(pos)))
```

### HSV-Space
```@example main
plot_butterfly(results; positions=positions, extra=(; topoPositionToColorFunction=UnfoldMakie.posToColorHSV))
```

### Uniform Color
To highlight the flexibility, we can also make all lines `gray`, or any other arbitrary color, or function of electrode-`position`.
```@example main
using Colors
plot_butterfly(results; positions=positions, extra=(; topoPositionToColorFunction = x -> Colors.RGB(0.5)))
```
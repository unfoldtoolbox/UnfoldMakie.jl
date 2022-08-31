# [Colorbar Data](@id config_colorbar)

The colorbar data of the configuration consists of config options for the colorbar that can be used as a legend.
As a consequence, the possible options are determined by the underlying functions.

## Line Plots
For line plots the `colorbar!` function of the `AlgebraOfGraphics` module is used ([documentation](http://juliaplots.org/AlgebraOfGraphics.jl/stable/API/functions/#AlgebraOfGraphics.colorbar!)).

The Colorbar will be automatically used when AlgebraOfGraphics is able to draw it, for this the `color` data will be used and has to be numerical and `extraData.categoricalColor` needs to be `false`.

## Other Plots
In all other Plots the `Colorbar` function of the `Makie` module is used ([documentation](https://makie.juliaplots.org/v0.17.13/examples/blocks/colorbar/index.html)).

The Colorbar will only be used when both `layoutData.showLegend` and `layoutData.useColorbar` are `true`

## Colorbar data default options

- vertical = `true`
- tellwidth = `true`
- tellheight = `true`
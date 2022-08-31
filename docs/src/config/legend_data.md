# [Legend Data](@id config_legend)

The legend data of the configuration consists of config options for the legend. 

## Line Plots and Butterfly Plots
For line plots the `legend!` function of the `AlgebraOfGraphics` module is used ([documentation](http://juliaplots.org/AlgebraOfGraphics.jl/stable/API/functions/#AlgebraOfGraphics.legend!)).

The Legend will be automatically used when AlgebraOfGraphics is able to draw it, for this the `color` data will be used and either has to be non-numerical or `config.extraData.categoricalColor` needs to be `true`.

## Parallel Coordinates Plots
In a parallel coordinate plot the `Legend` function of the `Makie` module is used ([documentation](https://makie.juliaplots.org/v0.17.13/examples/blocks/legend/index.html)).

The Legend will only be used when `config.layoutData.showLegend` is `true` and `config.layoutData.useColorbar` is `false`

## Legend data default options

- orientation = `:vertical`
- tellwidth = `true`
- tellheight = `true`

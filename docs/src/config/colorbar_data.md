# [Colorbar Data](@id config_colorbar)

The colorbar data of the configuration consists of config options for the colorbar that can be used as a legend. 

## Case: `drawing=nothing` and `config.layoutData.useColorbar=true`
The input of this config is directly fed into the `Colorbar` function of the `Makie` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the Makie documentation](https://makie.juliaplots.org/v0.17.13/examples/blocks/colorbar/index.html).


## Case: Not `drawing=nothing`
The input of this config is directly fed into the `colorbar` function of the `AlgebraOfGraphics` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the AlgebraOfGraphics documentation](http://juliaplots.org/AlgebraOfGraphics.jl/stable/API/functions/#AlgebraOfGraphics.colorbar!).


## TODO: Add content from plot_erp.jl ?


The following colorbar data options exist:

## vertical (boolean)
Indicating whether the colorbar should be aligned vertically.
Default is `true`.

## tellwidth (boolean)
-
Default is `true`.

## tellheight (boolean)
-
Default is `false`.
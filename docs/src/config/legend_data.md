# [Legend Data](@id config_legend)

The legend data of the configuration consists of config options for the legend. 

## Case: `drawing=nothing` and `config.layoutData.useColorbar=true` and `hm=nothing`
The input of this config is directly fed into the `Colorbar` function of the `Makie` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the Makie documentation](https://makie.juliaplots.org/v0.17.13/examples/blocks/colorbar/index.html).


## Case: `drawing=nothing` and `config.layoutData.useColorbar=false`
The input of this config is directly fed into the `Legend` function of the `Makie` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the Makie documentation](https://makie.juliaplots.org/v0.17.13/examples/blocks/legend/index.html).


## Case: Not `drawing=nothing`
The input of this config is directly fed into the `legend` function of the `AlgebraOfGraphics` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the AlgebraOfGraphics documentation](http://juliaplots.org/AlgebraOfGraphics.jl/stable/API/functions/#AlgebraOfGraphics.legend!).



## orientation ()
Indicates where the legend is placed.
Default is `:vertical`.

## tellwidth (boolean)
-
Default is `true`.

## tellheight (boolean)
-
Default is `false`.
# [Visual Data](@id config_visual)

The visual data of the configuration consists of config options for mapping color. 

## Case: Designmatrix, ERP Image
The input of this config is directly fed into the `heatmap` function of the `Makie` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the Makie documentation](https://makie.juliaplots.org/v0.17.13/examples/plotting_functions/heatmap/index.html).


## Case: Line Plot
The input of this config is directly fed into the `visual` function of the `AlgebraOfGraphics` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the AlgebraOfGraphics documentation](http://juliaplots.org/AlgebraOfGraphics.jl/stable/generated/visual/).


## Case: PCP
The input of this config is directly fed into the `lines` function of the `Makie` module. 
As a consequence, the possible options are also determined by the function. 
Details for these options can be found in the [corresponding article of the Makie documentation](https://makie.juliaplots.org/v0.17.13/examples/plotting_functions/lines/index.html).


## Case: Topo Plot
The input of this config is directly fed into either the `topoplot` function or the `eeg_topoplot` function (if config.plotType == :eegtopo) of the `TopoPlots` module. 
As a consequence, the possible options are also determined by the function. 


## TODO: Butterfly Plot?


## colormap ()

Indicating how the color is mapped.
Default is `:haline`.

The input of this config is directly fed into the `cgrad` function of the `PlotUtils` module. 
As a consequence, the possible options are also determined by the function.
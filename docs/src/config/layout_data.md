# [Layout Data](@id config_layout)

The layout data of the configuration consists of config options for the layout such as the legend and labels.

The following layout data options exist (the default values may be different for some plots types):

## showLegend (boolean)
Indicating whether the legend is displayed.
Default is `true`.

## legendPostion (Symbol)
Indicating the position and orientation of the legend.
Possible values are `:right` and `:bottom`.
Default is `:right`.

## useColorbar (boolean)
Indicating whether the colorbar should be used.
Default is `false`.

## xlabelFromMapping (Symbol/Nothing)
Which data column should be used for the xlabel.
Set to `nothing` if no column name should be used.
Default is `:x`.

## ylabelFromMapping (Symbol/Nothing)
Which data column should be used for the ylabel.
Set to `nothing` if no column name should be used.
Default is `:y`.

## other Makie functions
In addition to the previous options the `hidespines!` and `hidedecorations!` functions from the `Makie` module can be enabled by setting their respective parameters as follows.
```
config.setLayoutValues(
    ...
    hidespines = (:r, :t),
    hidedecorations = ()
)
```
Setting them to `nothing` will disable them.
More info on how to use them can be found in this [HowTo](@ref ht_hide_deco)
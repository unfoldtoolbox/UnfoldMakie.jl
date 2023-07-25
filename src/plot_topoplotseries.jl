"""
    function plot_topoplotseries!(f::Union{GridPosition, Figure}, plotData::DataFrame,Δbin::Real;kwargs...)
    function plot_topoplotseries!(plotData::DataFrame, Δbin::Real;kwargs...)
        

Plot a Topoplot Series.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: DataFrame with data, needs a `time` column
- `Δbin::Real`: A number for how many samples should be moved together to one topoplot
- `kwargs...`: Additional styling behavior. Often used: 
`plot_topoplotseries(df;mapping=(;col=:time,row=:conditionA))`

## Extra Data Behavior (...;extra=(;[key]=value)):
`combinefun` (default `mean`) can be used to specify how the samples within `Δbin` are combined.



## Return Value:
The input `f`

"""
plot_topoplotseries(plotData::DataFrame,Δbin::Real;kwargs...) = plot_topoplotseries!(Figure(), plotData, Δbin; kwargs...)


function plot_topoplotseries!(f::Union{GridPosition, Figure}, plotData::DataFrame, Δbin; positions=nothing, labels=nothing, kwargs...)
    config = PlotConfig(:topoplotseries)
    config_kwargs!(config;kwargs...)
    
    plotData = deepcopy(plotData)

    # resolve columns with data
    config.mapping = resolveMappings(plotData, config.mapping)

    positions = getTopoPositions(;positions=positions, labels=label)
    

    eeg_topoplot_series!(f, plotData, Δbin;
        col_y = config.mapping.y,
        col_label=:label,
        col = config.mapping.col,
        row = config.mapping.row,
        combinefun = config.extra.combinefun,
        positions=positions,
        config.visual...
        )

    return f
    
end

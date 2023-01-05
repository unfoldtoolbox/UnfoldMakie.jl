"""
    function plot_topoplotseries!(f::Union{GridPosition, Figure}, plotData::DataFrame,Δbin::Real, [config::PlotConfig];kwargs...)
    function plot_topoplotseries!(plotData::DataFrame, Δbin::Real,[config::PlotConfig];kwargs...)
        

Plot a Topoplot Series.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: DataFrame with data, needs a `time` column
- `Δbin::Real`: A number for how many samples should be moved together to one topoplot
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
- `kwargs...`: Additional styling behavior. Often used: 
`plot_topoplotseries(df;setMappingValues=(;col=:time,row=:conditionA))`

## Extra Data Behavior (...;setExtraValues=(;[key]=value)):
`combinefun` (default `mean`) can be used to specify how the samples within `Δbin` are combined.



## Return Value:
The input `f`

"""
plot_topoplotseries(plotData::DataFrame, Δbin::Real,    config::PlotConfig;kwargs...) = plot_topoplotseries!(Figure(), plotData, Δbin,config;kwargs...)
plot_topoplotseries(plotData::DataFrame,Δbin::Real;kwargs...) = plot_topoplotseries!(Figure(), plotData, Δbin,PlotConfig(:topoplotseries);kwargs...)


function plot_topoplotseries!(f::Union{GridPosition, Figure}, plotData::DataFrame, Δbin,config::PlotConfig;kwargs...)
    plotData = deepcopy(plotData)
    
    # set PlotDefaults      
    # e.g. config.setLayoutValues!(hidespines = (:r, :t))

    
    # apply config kwargs
    config_kwargs!(config;kwargs...)
    

    # resolve columns with data
    config.mappingData = resolveMappings(plotData,config.mappingData)

    
    
    allPositions = getTopoPositions(plotData, config)
    @show config.visualData
    eeg_topoplot_series!(f,plotData,Δbin;
        col_y = config.mappingData.topodata,
        col = config.mappingData.col,
        row = config.mappingData.row,
        combinefun = config.extraData.combinefun,
        positions=allPositions,
        config.visualData...
        )

    return f
    
end

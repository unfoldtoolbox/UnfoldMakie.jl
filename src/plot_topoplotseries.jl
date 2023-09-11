"""
    function plot_topoplotseries!(f::Union{GridPosition, Figure}, plotData::DataFrame,Δbin::Real;kwargs...)
    function plot_topoplotseries!(plotData::DataFrame, Δbin::Real;kwargs...)
        

Plot a Topoplot Series.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: DataFrame with data, needs a `time` column
- `Δbin::Real`: A number for how large one bin should be. Δbin is in units of the `plotData.time` column
- `kwargs...`: Additional styling behavior. Often used: 
`plot_topoplotseries(df;mapping=(;col=:time,row=:conditionA))`

## Extra Data Behavior (...;extra=(;[key]=value)):
`combinefun` (default `mean`) can be used to specify how the samples within `Δbin` are combined.
`bin_labels` (default `true`) - plot the time-window bin size as xlabels at the last row of the plot
`rasterize_heatmaps` (deault `true`) - when saving a svg - enforce rasterization of the plot heatmap. This has the benefit that all lines/points are vectors, except the interpolated heatmap. This is typically what you want, because else you get ~500x500 vectors per topoplot, which makes everything super slow...


## Return Value:
The input `f`

"""
plot_topoplotseries(plotData::DataFrame, Δbin::Real; kwargs...) = plot_topoplotseries!(Figure(), plotData, Δbin; kwargs...)


function plot_topoplotseries!(f::Union{GridPosition,Figure}, plotData::DataFrame, Δbin; positions=nothing, labels=nothing, kwargs...)
    config = PlotConfig(:topoplotseries)
    config_kwargs!(config; kwargs...)

    plotData = deepcopy(plotData)

    # resolve columns with data
    config.mapping = resolveMappings(plotData, config.mapping)

    positions = getTopoPositions(; positions=positions, labels=labels)

    
    if "label" ∉ names(plotData)
        plotData.label = plotData.channel
    end

    ftopo = eeg_topoplot_series!(f, plotData, Δbin;
        y=config.mapping.y,
        label=:label,
        col=config.mapping.col,
        row=config.mapping.row,
        col_labels = config.extra.col_labels,
        row_labels = config.extra.row_labels,
        rasterize_heatmaps = config.extra.rasterize_heatmaps,
        combinefun=config.extra.combinefun,
        positions=positions,
        config.visual...
    )

    if config.layout.showLegend
        @show "leegeeend"
        d = ftopo.content[1].scene.plots[1]
        
        Colorbar(f[1,end+1],colormap=d.colormap,colorrange=d.colorrange,height=100)
    end
    return f

end

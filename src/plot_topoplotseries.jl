"""
    plot_topoplotseries!(f::Union{GridPosition, GridLayout, Figure}, plotData::DataFrame, Δbin::Real; kwargs...)
    plot_topoplotseries!(plotData::DataFrame, Δbin::Real; kwargs...)
        
Multiple miniature topoplots in regular distances 

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: DataFrame with data, needs a `time` column
- `Δbin::Real`: A number for how large one bin should be. Δbin is in units of the `plotData.time` column
- `combinefun` (default `mean`) can be used to specify how the samples within `Δbin` are combined.
- `rasterize_heatmaps` (deault `true`) - enforce rasterization of the plot heatmap when saving in svg format.
 This has the benefit that all lines/points are vectors, except the interpolated heatmap. 
 This is typically what you want, because else you get ~500x500 vectors per topoplot, which makes everything super slow.
- `col_labels`, `row_labels` - shows column and row labels. 

$(_docstring(:topoplotseries))

## Return Value:
The input `f`

"""
plot_topoplotseries(plotData::DataFrame, Δbin::Real; kwargs...) =
    plot_topoplotseries!(Figure(), plotData, Δbin; kwargs...)

function plot_topoplotseries!(
    f::Union{GridPosition,GridLayout,Figure},
    plotData::DataFrame,
    Δbin;
    positions = nothing,
    labels = nothing,
    combinefun = mean,
    col_labels = true,
    row_labels = true,
    rasterize_heatmaps = true,
    kwargs...,
)

    config = PlotConfig(:topoplotseries)
    config_kwargs!(config; kwargs...)

    plotData = deepcopy(plotData)

    # resolve columns with data
    config.mapping = resolveMappings(plotData, config.mapping)
    positions = getTopoPositions(; positions = positions, labels = labels)


    if "label" ∉ names(plotData)
        plotData.label = plotData.channel
    end


    ftopo, axlist = eeg_topoplot_series!(
        f,
        plotData,
        Δbin;
        y = config.mapping.y,
        label = :label,
        col = config.mapping.col,
        row = config.mapping.row,
        col_labels = col_labels,
        row_labels = row_labels,
        rasterize_heatmaps = rasterize_heatmaps,
        combinefun = combinefun,
        positions = positions,
        config.visual...,
    )

    if config.layout.useColorbar
        if typeof(ftopo) == Figure
            d = ftopo.content[1].scene.plots[1]
            Colorbar(
                f[1, end+1],
                colormap = d.colormap,
                colorrange = d.colorrange,
                height = config.colorbar.height,
                flipaxis = config.colorbar.flipaxis,
                labelrotation = config.colorbar.labelrotation,
                label = config.colorbar.label,
            )
        else
            # println(fieldnames(typeof((axlist[1]))))
            d = axlist[1].scene.plots[1].attributes
            Colorbar(
                f[:, :][1, length(axlist)+1],
                colormap = d.colormap,
                colorrange = d.colorrange,
                height = config.colorbar.height,
                flipaxis = config.colorbar.flipaxis,
                labelrotation = config.colorbar.labelrotation,
                label = config.colorbar.label,
            )
        end
    end
    return f

end

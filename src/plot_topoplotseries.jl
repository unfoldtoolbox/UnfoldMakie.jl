"""
    plot_topoplotseries(f::Union{GridPosition, GridLayout, Figure}, data::DataFrame, Δbin::Real; kwargs...)
    plot_topoplotseries!(data::DataFrame, Δbin::Real; kwargs...)
        
Multiple miniature topoplots in regular distances 

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`: Figure or GridPosition that the plot should be drawn into.
- `data::DataFrame`: DataFrame with data, needs a `time` column.
- `Δbin::Real`: A number for how large one time bin should be. Δbin is in units of the `data.time` column.
- `combinefun` (default: `mean`) - can be used to specify how the samples within `Δbin` are combined.
- `rasterize_heatmaps` (default: `true`) - enforce rasterization of the plot heatmap when saving in svg format.
    This has the benefit that all lines/points are vectors, except the interpolated heatmap. 
    This is typically what you want, otherwise you get ~500x500 vectors per topoplot, which makes everything super slow.
- `col_labels`, `row_labels` - shows column and row labels. 
- labels (default: `nothing`) - .
- positions (default: `nothing`) - .

$(_docstring(:topoplotseries))

## Return Value:
The input `f`

"""
plot_topoplotseries(data::DataFrame, Δbin::Real; kwargs...) =
    plot_topoplotseries!(Figure(), data, Δbin; kwargs...)

function plot_topoplotseries!(
    f::Union{GridPosition,GridLayout,Figure},
    data::DataFrame,
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

    data = deepcopy(data)

    # resolve columns with data
    config.mapping = resolveMappings(data, config.mapping)
    positions = getTopoPositions(; positions = positions, labels = labels)


    if "label" ∉ names(data)
        data.label = data.channel
    end


    ftopo, axlist = eeg_topoplot_series!(
        f,
        data,
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

    if config.layout.use_colorbar
        if typeof(ftopo) == Figure
            d = ftopo.content[1].scene.plots[1]
            Colorbar(
                f[1, end+1],
                colormap = d.colormap,
                colorrange = d.colorrange,
                flipaxis = config.colorbar.flipaxis,
                labelrotation  = config.colorbar.labelrotation ,
                label = config.colorbar.label,
            )
        else
            # println(fieldnames(typeof((axlist[1]))))
            d = axlist[1].scene.plots[1].attributes
            Colorbar(
                f[:, :][1, length(axlist)+1],
                colormap = d.colormap,
                colorrange = d.colorrange,
                flipaxis = config.colorbar.flipaxis,
                labelrotation  = config.colorbar.labelrotation ,
                label = config.colorbar.label,
            )
        end
    end
    return f

end
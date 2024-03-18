"""
    plot_topoplotseries(f::Union{GridPosition, GridLayout, Figure}, data::DataFrame, Δbin::Real; kwargs...)
    plot_topoplotseries!(data::DataFrame, Δbin::Real; kwargs...)
        
Multiple miniature topoplots in regular distances. 
## Arguments  

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, Vector{Float32}}`\\
    DataFrame with data. Requires a `time` column.
- `Δbin::Real`\\
    A number for how large one time bin should be.\\
    `Δbin` is in units of the `data.time` column.

## Keyword arguments (kwargs)
- `combinefun::Function = mean`\\
    Specify how the samples within `Δbin` are summarised.\\
    Example functions: `mean`, `median`, `std`. 
- `rasterize_heatmaps::Bool = true`\\
    Force rasterization of the plot heatmap when saving in `svg` format.\\
    Except for the interpolated heatmap, all lines/points are vectors.\\
    This is typically what you want, otherwise you get ~128x128 vectors per topoplot, which makes everything super slow.
- `col_labels::Bool`, `row_labels::Bool = true`\\
    Shows column and row labels. 
- `labels::Vector{String} = nothing`\\
    Shows channel labels.
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Shows channel positions. Requires the list of all unique electrode x and y positions.

$(_docstring(:topoplotseries))

**Return Value:** `Figure` displaying the Topoplot series.
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
    config.mapping = resolve_mappings(data, config.mapping)

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
        d = axlist[1].scene.plots[1].attributes
        config_kwargs!(
            config,
            layout = (; use_colorbar = false, show_legend = false),
            colorbar = (; colormap = d.colormap, colorrange = d.colorrange),
        )
    else
        d = ftopo.content[1].scene.plots[1]
        config_kwargs!(
            config,
            colorbar = (; colormap = d.colormap, colorrange = d.colorrange),
        )
    end
    ax = Axis(
        f[1, 1],
        xlabel = config.axis.xlabel,
        ylabel = config.axis.ylabel,
        title = config.axis.title,
        titlesize = config.axis.titlesize,
        titlefont = config.axis.titlefont,
    )
    apply_layout_settings!(config; fig = f, ax = ax)
    return f

end

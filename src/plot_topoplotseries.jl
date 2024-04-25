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
    Show labels for each electrode.
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Specify channel positions. Requires the list of x and y positions for all unique electrode.

$(_docstring(:topoplotseries))

**Return Value:** `Figure` displaying the Topoplot series.
"""
plot_topoplotseries(data::DataFrame, Δbin::Real; kwargs...) =
    plot_topoplotseries!(Figure(), data, Δbin; kwargs...)

function plot_topoplotseries!(
    f::Union{GridPosition,GridLayout,Figure,GridLayoutBase.GridSubposition},
    data::Union{<:Observable{<:DataFrame},DataFrame},
    Δbin;
    positions = nothing,
    labels = nothing,
    combinefun = mean,
    col_labels = true,
    row_labels = true,
    rasterize_heatmaps = true,
    interactive_scatter = false,
    kwargs...,
)

    data = _as_observable(data)


    config = PlotConfig(:topoplotseries)
    # overwrite all defaults by user specified values
    config_kwargs!(config; kwargs...)


    # resolve columns with data
    config.mapping = resolve_mappings(to_value(data), config.mapping)


    cat_or_cont_columns =
        eltype(to_value(data)[!, config.mapping.col]) <: Number ? "cont" : "cat"
    if cat_or_cont_columns == "cat"
        # overwrite Time windows [s] default if categorical
        config_kwargs!(config; axis = (; xlabel = string(config.mapping.col)))
        config_kwargs!(config; kwargs...) # add the user specified once more, just if someone specifies the xlabel manually  
        # overkll as we would only need to check the xlabel ;)
    end

    positions = getTopoPositions(; positions = positions, labels = labels)

    chan_or_label = "label" ∉ names(to_value(data)) ? :channel : :label

    ftopo, axlist = eeg_topoplot_series!(
        f,
        data,
        Δbin;
        y = config.mapping.y,
        label = chan_or_label,
        col = config.mapping.col,
        row = config.mapping.row,
        col_labels = col_labels,
        row_labels = row_labels,
        rasterize_heatmaps = rasterize_heatmaps,
        combinefun = combinefun,
        xlim_topo = config.axis.xlim_topo,
        ylim_topo = config.axis.ylim_topo,
        interactive_scatter = interactive_scatter,
        config.visual...,
        positions,
    )
    if (config.colorbar.colorrange !== nothing)
        config_kwargs!(config)
    else
        data_mean = if cat_or_cont_columns == "cont"
            df_timebin(
                to_value(data),
                Δbin;
                col_y = config.mapping.y,
                fun = combinefun,
                grouping = [chan_or_label, config.mapping.col, config.mapping.row],
            )
        else
            to_value(data)
        end
        colorrange = extract_colorrange(data_mean, config.mapping.y)
        config_kwargs!(
            config,
            visual = (; colorrange = colorrange),
            colorbar = (; colorrange = colorrange),
        )
    end

    if !config.layout.use_colorbar
        config_kwargs!(config, layout = (; use_colorbar = false, show_legend = false))
    end

    ax = Axis(
        f[1, 1],
        xlabel = config.axis.xlabel,
        ylabel = config.axis.ylabel,
        title = config.axis.title,
        titlesize = config.axis.titlesize,
        titlefont = config.axis.titlefont,
        ylabelpadding = config.axis.ylabelpadding,
        xlabelpadding = config.axis.xlabelpadding,
    )
    apply_layout_settings!(config; fig = f, ax = ax)
    return f

end

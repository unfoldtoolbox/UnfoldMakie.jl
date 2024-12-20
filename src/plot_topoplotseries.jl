"""
    plot_topoplotseries(f::Union{GridPosition, GridLayout, Figure}, data::Union{<:Observable{<:DataFrame},DataFrame}; kwargs...)
    plot_topoplotseries!(data::Union{<:Observable{<:DataFrame},DataFrame}; kwargs...)
        
Multiple miniature topoplots in regular distances. 
## Arguments  

- `f::Union{GridPosition, GridLayout, GridLayoutBase.GridSubposition, Figure}`\\
    `Figure`, `GridLayout`, `GridPosition`, or `GridLayoutBase.GridSubposition` to draw the plot.
- `data::Union{<:Observable{<:DataFrame},DataFrame}`\\
    DataFrame with data or Observable DataFrame.\\
    Requires a `time` column by default, but can be overridden by specifying `mapping=(; x=:my_column)` with any continuous or categorical column. 

## Keyword arguments (kwargs)
- `bin_width::Real = nothing`\\
    Number specifing the width of bin of continuous x-value in its units.\\
- `bin_num::Real = nothing`\\
    Number of topoplots.\\
    Either `bin_width`, or `bin_num` should be specified. Error if they are both specified\\
    If `mapping.col` or `mapping.row` are categorical `bin_width` and `bin_num` stay as `nothing`.
- `combinefun::Function = mean`\\
    Specify how the samples within `bin_width` are summarised.\\
    Example functions: `mean`, `median`, `std`. 
- `rasterize_heatmaps::Bool = true`\\
    Force rasterization of the plot heatmap when saving in `svg` format.\\
    Except for the interpolated heatmap, all lines/points are vectors.\\
    This is typically what you want, otherwise you get ~128x128 vectors per topoplot, which makes everything very slow.
- `col_labels::Bool`, `row_labels::Bool = true`\\
    Shows column and row labels for categorical values. 
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Specify channel positions. Requires the list of x and y positions for all unique electrode.
 - `labels::Vector{String} = nothing`\\
    Show labels for each electrode.
- `interactive_scatter = nothing`\\
    Enable interactive mode.\\
    If you create `obs_tuple = Observable((0, 0, 0))` and pass it into `interactive_scatter` you can update the observable tuple with the indices of the clicked topoplot markers.\\
    `(0, 0, 0)` corresponds to the (row of topoplot layout, column of topoplot layout, electrode). 
- `topo_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of topoplots.\\
    To see all options just type `?Axis` in REPL.
- `mapping = (; col = :time`, row = nothing, layout = nothing)\\
    `mapping.col` - specify x-value, can be any continuous or categorical variable.\\
    `mapping.row` - specify y-value, can be any continuous or categorical variable (not implemented yet).\\
    `mapping.layout` - arranges topoplots by rows when equals `:time`.\\
- `visual.colorrange::2-element Vector{Int64}`\\
    Resposnible for colorrange in topoplots and in colorbar.
- `topo_attributes::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot interoplation.\\
    To see all options just type `?Topoplot.topoplot` in REPL.\\
    Defaults: $(supportive_defaults(:topo_default_attributes))
Code description:
- 
$(_docstring(:topoplotseries))

**Return Value:** `Figure` displaying the Topoplot series.
"""
plot_topoplotseries(data::Union{<:Observable{<:DataFrame},DataFrame}; kwargs...) =
    plot_topoplotseries!(Figure(), data; kwargs...)

function plot_topoplotseries!(
    f::Union{GridPosition,GridLayout,Figure,GridLayoutBase.GridSubposition},
    data::Union{<:Observable{<:DataFrame},DataFrame};
    bin_width = nothing,
    bin_num = nothing,
    positions = nothing,
    labels = nothing,
    nrows = 1,
    combinefun = mean,
    col_labels = false,
    row_labels = true,
    rasterize_heatmaps = true,
    interactive_scatter = nothing,
    topo_axis = (;),
    topo_attributes = (;),
    kwargs...,
)

    data = _as_observable(data)
    data_cuts = data
    positions = get_topo_positions(; positions = positions, labels = labels)
    chan_or_label = "label" ∉ names(to_value(data)) ? :channel : :label

    config = PlotConfig(:topoplotseries)
    # overwrite all defaults by user specified values
    config_kwargs!(config; kwargs...)
    topo_attributes = update_axis(
        supportive_defaults(:topo_default_attributes);
        topo_attributes...,
        config.visual...,
    )

    if !isnothing(labels) && length(labels) != length(positions)
        error(
            "The length of `labels` differs from the length of `position`. Please make sure they are the same length.",
        )
    end
    # resolve columns with data
    config.mapping = resolve_mappings(to_value(data), config.mapping)
    data_copy = deepcopy(to_value(data)) # deepcopy prevents overwriting initial data
    cat_or_cont_columns =
        eltype(data_copy[!, config.mapping.col]) <: Number ? "cont" : "cat"
    if cat_or_cont_columns == "cat"
        # overwrite 'Time windows [s]' default if categorical
        n_topoplots =
            number_of_topoplots(data_copy; bin_width, bin_num, bins = 0, config.mapping)
        ix =
            findall.(
                isequal.(unique(data_copy[!, config.mapping.col])),
                [data_copy[!, config.mapping.col]],
            )
    else
        bins = bins_estimation(
            data_copy[!, config.mapping.col];
            bin_width,
            bin_num,
            cat_or_cont_columns,
        )
        n_topoplots =
            number_of_topoplots(data_copy; bin_width, bin_num, bins, config.mapping)
        to_value(data_cuts).cont_cuts =
            cut(to_value(data_cuts)[!, config.mapping.col], bins; extend = true)
        unique_cuts = unique(to_value(data_cuts).cont_cuts)
        ix = findall.(isequal.(unique_cuts), [to_value(data).cont_cuts])
    end
    data_row = @lift row_col_management($data_cuts, ix, n_topoplots, nrows, config)
    config_kwargs!(
        config;
        mapping = (; row = :row_coord, col = :col_coord),
        axis = (; xlabel = string(config.mapping.col)),
    )
    config_kwargs!(config; kwargs...)  #add the user specified once more, just if someone specifies the xlabel manually  
    # overkill as we would only need to check the xlabel ;)

    ftopo, axlist, colorrange = eeg_topoplot_series!(
        f,
        data_row;
        cat_or_cont_columns = cat_or_cont_columns,
        y = config.mapping.y,
        label = chan_or_label,
        col = config.mapping.col,
        row = config.mapping.row,
        col_labels = col_labels,
        row_labels = row_labels,
        rasterize_heatmaps = rasterize_heatmaps,
        combinefun = combinefun,
        interactive_scatter = interactive_scatter,
        topo_axis = topo_axis,
        topo_attributes = topo_attributes,
        positions,
        labels,
    )
    config_kwargs!(
        config,
        visual = (; colorrange = colorrange),
        colorbar = (; colorrange = colorrange),
    )

    ax = Axis(
        f[1, 1];
        (p for p in pairs(config.axis) if p[1] != :xlim_topo && p[1] != :ylim_topo)...,
    )
    if config.layout.use_colorbar == true
        Colorbar(f[1, 2]; colormap = config.visual.colormap, config.colorbar...)
    end

    apply_layout_settings!(config; fig = f, ax = ax)
    return f
end

function row_col_management(data, ix, n_topoplots, nrows, config)
    if :layout ∈ keys(config.mapping)
        n_cols = Int(ceil(sqrt(n_topoplots)))
        n_rows = Int(ceil(n_topoplots / n_cols))
    else
        n_rows = nrows
        if 0 > n_topoplots / nrows
            @warn "Impossible number of rows, set to 1 row"
            n_rows = 1
        elseif n_topoplots / nrows < 1
            @warn "Impossible number of rows, set to $(n_topoplots) rows"
        end
        n_cols = Int(ceil(n_topoplots / n_rows))
    end
    col_coord = repeat(1:n_cols, outer = n_rows)[1:n_topoplots]
    row_coord = repeat(1:n_rows, inner = n_cols)[1:n_topoplots]
    data.col_coord .= 1
    data.row_coord .= 1
    for topo = 1:n_topoplots
        data.col_coord[ix[topo]] .= col_coord[topo]
        data.row_coord[ix[topo]] .= row_coord[topo]
    end
    return data
end

function bins_estimation(
    continous_value;
    bin_width = nothing,
    bin_num = nothing,
    cat_or_cont_columns = "cont",
)
    c_min = minimum(continous_value)
    c_max = maximum(continous_value)
    if (!isnothing(bin_width) && !isnothing(bin_num))
        error("Ambigious parameters: specify only `bin_width` or `bin_num`.")
    elseif (isnothing(bin_width) && isnothing(bin_num) && cat_or_cont_columns == "cont")
        error(
            "You haven't specified `bin_width` or `bin_num`. Such option is available only with categorical `mapping.col` or `mapping.row`.",
        )
    end
    if isnothing(bin_width)
        bins = range(; start = c_min, length = bin_num + 1, stop = c_max)
    else
        bins = range(; start = c_min, step = bin_width, stop = c_max)
    end
    return bins
end

function number_of_topoplots(
    df::DataFrame;
    bin_width = nothing,
    bin_num = nothing,
    bins,
    mapping = config.mapping,
)
    if !isnothing(bin_width) | !isnothing(bin_num)
        if typeof(df[:, mapping.col]) == Vector{String}
            error(
                "Parameters `bin_width` or `bin_num` are only allowed with continonus `mapping.col` or `mapping.row`, while you specifed categorical.",
            )
        end
        cont_new = cut(df[:, mapping.col], bins; extend = true)
        n = length(unique(cont_new))
    else
        n = length(unique(df[:, mapping.col]))
    end
    return n
end

"""
    plot_topoplotseries(f::Union{GridPosition, GridLayout, Figure}, data::DataFrame; kwargs...)
    plot_topoplotseries!(data::DataFrame; kwargs...)
        
Multiple miniature topoplots in regular distances. 
## Arguments  

- `f::Union{GridPosition, GridLayout, GridLayoutBase.GridSubposition, Figure}`\\
    `Figure`, `GridLayout`, `GridPosition`, or GridLayoutBase.GridSubposition to draw the plot.
- `data::Union{<:Observable{<:DataFrame},DataFrame}`\\
    DataFrame with data or Observable DataFrame. Requires a `time` column. 

## Keyword arguments (kwargs)
- `bin_width::Real = nothing`\\
    Number specifing the width of time bin.\\
    `bin_width` is in units of the `data.time` column.\\
- `bin_num::Real = nothing`\\
    Number of topoplots.\\
    Either `bin_width`, or `bin_num` should be specified. Error if they are both specified\\
    If `mapping.col` or `mapping.row` are categorical `bin_width` and `bin_num` should be `nothing`.
- `combinefun::Function = mean`\\
    Specify how the samples within `bin_width` are summarised.\\
    Example functions: `mean`, `median`, `std`. 
- `rasterize_heatmaps::Bool = true`\\
    Force rasterization of the plot heatmap when saving in `svg` format.\\
    Except for the interpolated heatmap, all lines/points are vectors.\\
    This is typically what you want, otherwise you get ~128x128 vectors per topoplot, which makes everything super slow.
- `col_labels::Bool`, `row_labels::Bool = true`\\
    Shows column and row labels for categorical values (?). 
- `labels::Vector{String} = nothing`\\
    Show labels for each electrode.
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Specify channel positions. Requires the list of x and y positions for all unique electrode.
- `interactive_scatter = nothing`\\
    Enable interactive mode. \\ 
    If you create `obs_tuple = Observable((0, 0, 0))` and pass it into `interactive_scatter` you can change observable indecies by clicking topopplot markers.\\
    `(0, 0, 0)` corresponds to the indecies of row of topoplot layout, column of topoplot layout and channell. 
- `mapping.layout = nothing`\\
    When equals `:time` arrange topoplots by rows. 


$(_docstring(:topoplotseries))

**Return Value:** `Figure` displaying the Topoplot series.
"""
plot_topoplotseries(data::DataFrame; kwargs...) =
    plot_topoplotseries!(Figure(), data; kwargs...)

function plot_topoplotseries!(
    f::Union{GridPosition,GridLayout,Figure,GridLayoutBase.GridSubposition},
    data::Union{<:Observable{<:DataFrame},DataFrame};
    bin_width = nothing,
    bin_num = nothing,
    positions = nothing,
    nrows = 1,
    labels = nothing, # rename to channel_labels?
    combinefun = mean,
    col_labels = false,
    row_labels = true,
    rasterize_heatmaps = true,
    interactive_scatter = nothing,
    kwargs...,
)

    data = _as_observable(data)
    positions = get_topo_positions(; positions = positions, labels = labels)
    chan_or_label = "label" ∉ names(to_value(data)) ? :channel : :label

    config = PlotConfig(:topoplotseries)
    # overwrite all defaults by user specified values
    config_kwargs!(config; kwargs...)

    # resolve columns with data
    config.mapping = resolve_mappings(to_value(data), config.mapping)
    cat_or_cont_columns =
        eltype(to_value(data)[!, config.mapping.col]) <: Number ? "cont" : "cat"
    data = deepcopy(to_value(data))
    if cat_or_cont_columns == "cat"
        # overwrite Time windows [s] default if categorical
        config_kwargs!(config; axis = (; xlabel = string(config.mapping.col)))
        config_kwargs!(config; kwargs...) # add the user specified once more, just if someone specifies the xlabel manually  
        # overkll as we would only need to check the xlabel ;)
    else
        # arrangment of topoplots by rows and cols
        bins = bins_estimation(data.time; bin_width, bin_num, cat_or_cont_columns)
        n_topoplots = number_of_topoplots(data; bin_width, bin_num, bins, config.mapping)

        data.timecuts = cut(data.time, bins; extend = true)
        unique_cuts = unique(data.timecuts)
        ix = findall.(isequal.(unique_cuts), [data.timecuts])
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
        _col = repeat(1:n_cols, outer = n_rows)[1:n_topoplots]
        _row = repeat(1:n_rows, inner = n_cols)[1:n_topoplots]
        data._col .= 1
        data._row .= 1
        for topo = 1:n_topoplots
            data._col[ix[topo]] .= _col[topo]
            data._row[ix[topo]] .= _row[topo]
        end
        config_kwargs!(config; mapping = (; row = :_row, col = :_col))
    end

    ftopo, axlist = eeg_topoplot_series!(
        f,
        data;
        bin_width = bin_width,
        bin_num = bin_num,
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
                to_value(data);
                bin_width,
                bin_num,
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
        f[1, 1];
        (p for p in pairs(config.axis) if p[1] != :xlim_topo && p[1] != :ylim_topo)...,
    )
    apply_layout_settings!(config; fig = f, ax = ax)
    return f
end

function bins_estimation(time; bin_width = nothing, bin_num = nothing, cat_or_cont_columns)
    tmin = minimum(time)
    tmax = maximum(time)
    if (!isnothing(bin_width) && !isnothing(bin_num))
        error("Ambigious parameters: specify only `bin_width` or `bin_num`.")
    elseif (isnothing(bin_width) && isnothing(bin_num) && cat_or_cont_columns == "cont")
        error(
            "You haven't specified `bin_width` or `bin_num`. Such option is available only with categorical `mapping.col` or `mapping.row`.",
        )
    end
    if isnothing(bin_width)
        bins = range(; start = tmin, length = bin_num + 1, stop = tmax)
    else
        bins = range(; start = tmin, step = bin_width, stop = tmax)
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
    if !isnothing(bin_width)
        time_new = cut(df.time, bins; extend = true)
        n = length(unique(time_new))
    elseif !isnothing(bin_num)
        time_new = cut(df.time, bins; extend = true)
        n = length(unique(time_new))
    else
        n = unique(df[:, mapping.col])
    end
    return n
end


"""
    df_timebin(df, bin_width; col_y = :erp, fun = mean, grouping = [])
Split or combine `DataFrame` according to equally spaced time bins.

Arguments:
- `df::AbstractTable`\\
    With columns `:time` and `col_y` (default `:erp`), and all columns in `grouping`;
- `bin_width::Real = nothing`\\
    Bin width in `:time` units;
- `bin_num::Real = nothing`\\
    Number of topoplots;
- `col_y = :erp` \\
    The column to combine over (with `fun`);
- `fun = mean()`\\
    Function to combine.
- `grouping = []`\\
    Vector of symbols or strings, columns to group the data by before aggregation. Values of `nothing` are ignored.

**Return Value:** `DataFrame`.
"""
function df_timebin(
    df;
    bin_width = nothing,
    bin_num = nothing,
    col_y = :erp,
    fun = mean,
    grouping = [],
)
    bins = bins_estimation(df.time; bin_width, bin_num, cat_or_cont_columns = "cont")
    df = deepcopy(df) # cut seems to change stuff inplace
    df.time = cut(df.time, bins; extend = true)

    grouping = grouping[.!isnothing.(grouping)]
    df_m = combine(groupby(df, unique([:time, grouping...])), col_y => fun)
    rename!(df_m, names(df_m)[end] => col_y) # remove the fun part of the new column

    return df_m
end

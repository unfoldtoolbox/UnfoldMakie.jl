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
    Shows column and row labels in faceting mode. (not implemented)
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Specify channel positions. Requires the list of x and y positions for all unique electrodes.
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
- `topo_attributes::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot interoplation.\\
    To see all options just type `?Topoplot.topoplot` in REPL.\\
    Defaults: $(replace(string(supportive_defaults(:topo_default_attributes; docstring = true)), "_" => "\\_"))

$(_docstring(:topoplotseries))

**Return Value:** `Figure` displaying the Topoplot series.
"""
plot_topoplotseries(data::Union{<:Observable{<:DataFrame},DataFrame}; kwargs...) =
    plot_topoplotseries!(Figure(), data; kwargs...)

function plot_topoplotseries!(
    f::Union{GridPosition,GridLayout,Figure,GridLayoutBase.GridSubposition},
    data_inp::Union{<:Observable{<:DataFrame},DataFrame};
    bin_width = nothing,
    bin_num = nothing,
    positions = nothing,
    labels = nothing,
    nrows = 1,
    combinefun = mean,
    col_labels = nothing,
    row_labels = nothing,
    rasterize_heatmaps = true,
    interactive_scatter = nothing,
    topo_axis = (;),
    topo_attributes = (;),
    topolabels_rounding = (; sigdigits = 3),
    #uncertainty = false,
    kwargs...,
)

    @assert(
        isnothing(col_labels) & isnothing(row_labels),
        "col_labels and row_labels are not implemented right now. please contact us if you need them"
    )
    data = _as_observable(data_inp)
    positions = get_topo_positions(; positions = positions, labels = labels)

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
    # check number of topoplots and group the data accordint to their location
    data_row, topoplot_xlables, layout =
        cutting_management(data, bin_width, bin_num, combinefun, nrows, config)

    # Replace and round numeric labels in `topoplot_xlables`
    topoplot_xlables = @lift replace.(
        $topoplot_xlables,
        r"\d+\.\d+"i => x -> begin # r"\d+\.\d+"i will check for cases like "1.0" and avoid "A.0"
            num = round_number(x, topolabels_rounding) # this number should be adjustable
        end,
    )

    ftopo, axlist = eeg_topoplot_series!(
        f[1, 1],
        data_row;
        layout,
        topoplot_xlables,
        #col_labels, # TODO
        #row_labels, # TODO
        rasterize_heatmaps,
        interactive_scatter,
        topo_axis,
        topo_attributes,
        positions,
        labels,
    )
    cb_limits = (minimum(data.val.estimate), maximum(data.val.estimate)) # set limits for colorbar
    cb_ticks = LinRange(cb_limits[1], cb_limits[2], 5) # set ticklables for colorbar
    rounded_ticks = round.(cb_ticks, digits = 2)

    config_kwargs!(
        config;
        # mapping = (; row = :row_coord, col = :col_coord),
        axis = (; xlabel = string(config.mapping.col)),
        colorbar = (; limits = cb_limits, ticks = (cb_ticks, string.(rounded_ticks))),
    )
    config_kwargs!(config; kwargs...)  #add the user specified once more, just if someone specifies the xlabel manually  
    # overkill as we would only need to check the xlabel ;) 

    ax = Axis(
        f[1, 1];
        (p for p in pairs(config.axis) if p[1] != :xlim_topo && p[1] != :ylim_topo)..., # what it this??
    )
    if config.layout.use_colorbar == true
        Colorbar(f[1, 2]; colormap = config.visual.colormap, config.colorbar...)
    end

    apply_layout_settings!(config; fig = f, ax = ax)
    return f
end

#round(323434.2323;(;sigdigits=3)...) - other way to implement it
function round_number(x, rounding_config)
    if haskey(rounding_config, :digits) && haskey(rounding_config, :sigdigits)
        error(
            "Only one of :digits or :sigdigits should be provided in topolabels_rounding.",
        )
    elseif haskey(rounding_config, :digits)
        round(parse(Float64, x), digits = rounding_config[:digits])
    elseif haskey(rounding_config, :sigdigits)
        round(parse(Float64, x), sigdigits = rounding_config[:sigdigits])
    else
        error("Rounding configuration must contain either :digits or :sigdigits.")
    end
end

function cutting_management(data, bin_width, bin_num, combinefun, nrows, config)
    cat_or_cont_columns =
        @lift eltype($data[!, config.mapping.col]) <: Number ? "cont" : "cat"
    chan_or_label = "label" ∉ names(to_value(data)) ? :channel : :label
    if to_value(cat_or_cont_columns) == "cat"
        # overwrite 'Time windows [s]' default if categorical
        n_topoplots =
            @lift number_of_topoplots($data; bin_width, bin_num, bins = 0, config.mapping)
        df_grouped = @lift groupby($data, unique([config.mapping.col, chan_or_label]))
        df_combined = @lift combine($df_grouped, :estimate => combinefun => :estimate)
        data_unstacked = @lift unstack($df_combined, :channel, :estimate)
        data_row = @lift Matrix($data_unstacked[:, 2:end])'
    else
        bins = @lift bins_estimation(
            $data[!, config.mapping.col];
            bin_width,
            bin_num,
            cat_or_cont_columns = $cat_or_cont_columns,
        )

        n_topoplots = @lift number_of_topoplots(
            $data;
            bin_width,
            bin_num,
            bins = $bins,
            config.mapping,
        )

        cont_cuts = @lift cut($data[!, config.mapping.col], $bins; extend = true)

        data_binned = @lift data_binning(
            $data;
            col_y = config.mapping.y,
            fun = combinefun,
            grouping = [chan_or_label],
            cont_cuts,
        )
        data_unstacked = @lift unstack($data_binned, :channel, :estimate)
        data_row = @lift Matrix($data_unstacked[:, 2:end])'
    end

    topoplot_xlables = @lift string.(($data_unstacked[:, 1]))

    rows, cols = row_col_management(to_value(n_topoplots), nrows, config)
    layout = map((x, y) -> (x, y), to_value(rows), to_value(cols))
    return data_row, topoplot_xlables, layout
end

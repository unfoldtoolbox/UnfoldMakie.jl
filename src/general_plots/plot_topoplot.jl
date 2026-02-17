"""
    plot_topoplot!(f::Union{GridPosition, GridLayout, Figure}, data::Union{<:Observable{<:DataFrame},<:AbstractDataFrame,<:AbstractVector}; positions::Vector, labels = nothing, kwargs...)
    plot_topoplot(data::Union{<:Observable{<:DataFrame},<:AbstractDataFrame,<:AbstractVector}; position::Vector, labels = nothing, kwargs...)

Plot a topoplot.
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{<:Observable{<:DataFrame},<:AbstractDataFrame,<:AbstractVector}` \\
    Data for the plot visualization.
- `positions::Vector{Point{2, Float32}}`\\
    Positions used if `data` is not a `DataFrame`. Positions are generated from `labels` if `positions = nothing`.
- `labels::Vector{String} = nothing`\\
    Labels used if `data` is not a DataFrame.
- `topo_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot axis.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:topo_default_single))
- `topo_attributes::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot interoplation.\\
    To see all options just type `?Topoplot.topoplot` in REPL.\\
    Defaults: $(replace(string(supportive_defaults(:topo_default_attributes; docstring = true)), "_" => "\\_"))
$(_docstring(:topoplot))

To highlight some electrodes, you can use `topo_attributes = (; label_scatter = (; ...))`,  where `...` are the attributes for `scatter!` function.  For example, to change the marker size of all electrodes to 8,  use `topo_attributes = (; label_scatter = (; markersize = 15))`. 
To set different sizes for each electrode, provide a vector of sizes with length equal 
to the number of electrodes.

Colorbar limits behavior:
- If you pass `colorbar = (; limits = (lo, hi))` or `colorbar = (; colorrange = (lo, hi))`, that range is used.\\
- If neither is provided and the data includes negative values, the range is symmetric around zero using 1st/99th percentiles:
  `p01 = percentile(0.01, data)`, `p99 = percentile(0.99, data)`, `m = max(abs(p01), abs(p99))`, then `(-m, m)`.
- If the data is non-negative, the range defaults to `(minimum(data), maximum(data))`.

**Return Value:** `Figure` displaying the Topoplot.
"""
plot_topoplot(
    data::Union{
        <:Observable{<:DataFrame},
        <:Observable{<:AbstractVector},
        <:AbstractDataFrame,
        <:AbstractVector,
    };
    kwargs...,
) = plot_topoplot!(Figure(), data; kwargs...)

function plot_topoplot!(
    f::Union{GridPosition,GridLayout,GridLayoutBase.GridSubposition,Figure},
    data::Union{
        <:Observable{<:DataFrame},
        <:Observable{<:AbstractVector},
        <:AbstractDataFrame,
        <:AbstractVector,
    };
    labels = nothing,
    positions = nothing,
    topo_attributes = (;),
    topo_axis = (;),
    kwargs...,
)

    config = PlotConfig(:topoplot)
    config_kwargs!(config; kwargs...) # potentially should be combined

    great_axis = f[1, 1] = GridLayout()

    if !(data isa Vector || data isa Observable{<:AbstractVector})
        config.mapping = resolve_mappings(data, config.mapping)
        data = data[:, config.mapping.y]
    end
    data = _as_observable(data)
    if isnothing(positions) && !isnothing(labels)
        positions = TopoPlots.labels2positions(labels)
    end
    positions = get_topo_positions(; positions = positions, labels = labels)
    topo_attributes =
        update_axis(supportive_defaults(:topo_default_attributes); topo_attributes...)
    topo_axis = update_axis(supportive_defaults(:topo_default_single); topo_axis...)

    if haskey(config.colorbar, :limits) || haskey(config.colorbar, :colorrange)
        error(
            "Topoplot uses a shared color range between the plot and colorbar. " *
            "Set `visual = (; colorrange = (lo, hi))` (or `visual = (; limits = ...)`) " *
            "instead of `colorbar = (; limits/colorrange = ...)`.",
        )
    end

    # Resolve a single range source, then link it to the topoplot + colorbar.
    # Keep colorrange in Float32 to match Makie internals; avoids first tick being
    # dropped due to Float64 ↔ Float32 rounding at the limits.
    shared_range = topo_shared_range(data, config.visual)
    config_kwargs!(config, visual = (; colorrange = shared_range))

    location = get(config.colorbar, :location, nothing)
    if !(location === nothing || location in (:right, :left, :top, :bottom))
        error("colorbar.location must be one of :right, :left, :top, :bottom")
    end

    row_offset = location == :top ? 1 : 0
    col_offset = location == :left ? 1 : 0
    plot_rows = (1 + row_offset):(4 + row_offset)
    plot_cols = (1 + col_offset):(2 + col_offset)

    outer_axis = Axis(great_axis[plot_rows, plot_cols]; config.axis...)
    hidespines!(outer_axis); hidedecorations!(outer_axis, label = false)

    inner_axis = Axis(great_axis[plot_rows, plot_cols]; topo_axis...)
    h = eeg_topoplot!(
        inner_axis,
        data;
        labels = labels,
        positions,
        config.visual...,
        topo_attributes...,
    )
    if shared_range[][1] ≈ shared_range[][2]
        @warn """The min and max of the value represented by the color are the same, it seems that the data values are identical. 
We disable the color bar in this figure.
Note: The identical min and max may cause an interpolation error when plotting the topoplot."""
        config_kwargs!(config, layout = (; use_colorbar = false))
    else
        if !haskey(config.colorbar, :ticks)
            ticks = @lift LinRange($shared_range[1], $shared_range[2], 5)
            rounded_ticks = @lift string.(round.($ticks, digits = 2))  # Round to 2 decimal places
            @lift config_kwargs!(config, colorbar = (; ticks = ($ticks, $rounded_ticks)))
        end
    end
    if config.layout.use_colorbar
        cb_pos = if location == :right
            great_axis[plot_rows, plot_cols.stop + 1]
        elseif location == :left
            great_axis[plot_rows, plot_cols.start-1]
        elseif location == :top
            great_axis[plot_rows.start - 1, plot_cols]
        else
            great_axis[plot_rows.stop + 1, plot_cols]
        end

        if !get(config.colorbar, :vertical, true)
            config_kwargs!(config, colorbar = (; labelrotation = 2π))
        end

        # When linking a colorbar to a plot object, Makie forbids passing limits/colorrange.
        cb_kwargs = (; (k => v for (k, v) in pairs(config.colorbar)
                        if !(k in (:limits, :colorrange, :location)))...)
        cb = Colorbar(cb_pos, h; cb_kwargs...)
    
        if location == :top
            rowgap!(great_axis, plot_rows.start - 1, 0)
            rowsize!(great_axis, plot_rows.start - 1, Auto(0.1))
        elseif location == :bottom
            rowgap!(great_axis, plot_rows.stop, 10)
            rowsize!(great_axis, plot_rows.stop + 1, Auto(0.1))
            outer_axis.xlabelpadding = -6
        elseif location == :left || location == :right
            colgap!(great_axis, location == :left ? plot_cols.start - 1 : plot_cols.stop, 0)
            colsize!(great_axis, location == :left ? plot_cols.start - 1 : plot_cols.stop + 1, Auto(0.1))
        end
    end
    apply_layout_settings!(config; fig = f)
    return f
end

function _percentile(p::Real, v::AbstractVector)
    n = length(v)
    n == 0 && throw(ArgumentError("percentile of empty collection"))
    s = sort(v)
    idx = clamp(ceil(Int, p * n), 1, n)
    return s[idx]
end

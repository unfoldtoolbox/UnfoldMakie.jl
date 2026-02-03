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

To highlight some electrodes, you can use `topo_attributes = (; label_scatter = (; ...))`  where `...` are the attributes for `scatter!` function.  For example, to change the marker size of all electrodes to 8,  use `topo_attributes = (; label_scatter = (; markersize = 15))`. 
To set different sizes for each electrode, provide a vector of sizes with length equal 
to the number of electrodes.

Colorbar limits behavior:
- If you pass `colorbar = (; limits = (lo, hi))` or `colorbar = (; colorrange = (lo, hi))`, that range is used.
- If neither is provided, the range is computed from the data as symmetric 5th/95th percentiles:
  `p05 = percentile(0.05, data)`, `p95 = percentile(0.95, data)`, `m = max(abs(p05), abs(p95))`, then `(-m, m)`.

**Return Value:** `Figure` displaying the Topoplot.
"""

# Simple percentile without external deps (p in (0, 1]).
function _percentile(p::Real, v::AbstractVector)
    n = length(v)
    n == 0 && throw(ArgumentError("percentile of empty collection"))
    s = sort(v)
    idx = clamp(ceil(Int, p * n), 1, n)
    return s[idx]
end

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
    outer_axis = Axis(great_axis[1:4, 1:2]; config.axis...)
    hidespines!(outer_axis)
    hidedecorations!(outer_axis, label = false)

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
    inner_axis = Axis(great_axis[1:4, 1:2]; topo_axis...)

    eeg_topoplot!(
        inner_axis,
        data;
        labels = labels,
        positions,
        config.visual...,
        topo_attributes...,
    )

    # Determine color range for ticks; respect user-provided limits/colorrange if present.
    if haskey(config.visual, :limits)
        clims = Observable(config.visual.limits)
    else
        clims = @lift begin
            p05 = _percentile(0.05, $data)
            p95 = _percentile(0.95, $data)
            m = max(abs(p05), abs(p95))
            (-m, m)
        end
    end
    colorbar_range = if haskey(config.colorbar, :limits)
        Observable(config.colorbar.limits)
    elseif haskey(config.colorbar, :colorrange)
        Observable(config.colorbar.colorrange)
    else
        clims
    end

    if colorbar_range[][1] ≈ colorbar_range[][2]
        @warn """The min and max of the value represented by the color are the same, it seems that the data values are identical. 
We disable the color bar in this figure.
Note: The identical min and max may cause an interpolation error when plotting the topoplot."""
        config_kwargs!(config, layout = (; use_colorbar = false))
    else

        ticks = @lift LinRange($colorbar_range[1], $colorbar_range[2], 5)
        rounded_ticks = @lift string.(round.($ticks, digits = 2))  # Round to 2 decimal places
        if haskey(config.colorbar, :limits) || haskey(config.colorbar, :colorrange)
            @lift config_kwargs!(config, colorbar = (; ticks = ($ticks, $rounded_ticks)))
        else
            @lift config_kwargs!(
                config,
                colorbar = (; ticks = ($ticks, $rounded_ticks), limits = $colorbar_range),
            )
        end
    end
    if config.layout.use_colorbar
        isvert = get(config.colorbar, :vertical, true)
        cb_pos = isvert ? great_axis[1:4, 2] : great_axis[5, 1:2]

        if !isvert
            config_kwargs!(config, colorbar = (; labelrotation = 2π, flipaxis = false))
        end

        Colorbar(
            cb_pos;
            colormap = config.visual.colormap,
            config.colorbar...,
        )
        !isvert && rowgap!(great_axis, 4, 0)
    end
    apply_layout_settings!(config; fig = f)
    return f
end

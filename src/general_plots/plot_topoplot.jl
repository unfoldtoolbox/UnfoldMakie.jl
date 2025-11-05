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

    # Set the color limits (`clims`) either from the config if specified by user or dynamically based on the data.
    if haskey(config.visual, :limits)
        clims = Observable(config.visual.limits)
    else
        clims = @lift (min($data...), max($data...))
    end

    if clims[][1] ≈ clims[][2]
        @warn """The min and max of the value represented by the color are the same, it seems that the data values are identical. 
We disable the color bar in this figure.
Note: The identical min and max may cause an interpolation error when plotting the topoplot."""
        config_kwargs!(config, layout = (; use_colorbar = false))
    else

        ticks = @lift LinRange($clims[1], $clims[2], 5)
        rounded_ticks = @lift string.(round.($ticks, digits = 2))  # Round to 2 decimal places
        @lift config_kwargs!(
            config,
            colorbar = (; ticks = ($ticks, $rounded_ticks), limits = $clims),
        )
    end
    if config.layout.use_colorbar == true
        if config.colorbar.vertical == true
            Colorbar(great_axis[1:4, 2]; colormap = config.visual.colormap, config.colorbar...)
        else
            config_kwargs!(config, colorbar = (; labelrotation = 2π, flipaxis = false))
            Colorbar(great_axis[5, 1:2]; colormap = config.visual.colormap, config.colorbar...)
            rowgap!(great_axis, 4, 0)
        end
    end
    apply_layout_settings!(config; fig = f)
    return f
end

"""
    plot_topoplot!(f::Union{GridPosition, GridLayout, Figure}, data::Union{<:AbstractDataFrame,<:AbstractVector}; positions::Vector, labels = nothing, kwargs...)
    plot_topoplot(data::Union{<:AbstractDataFrame,<:AbstractVector}; position::Vector, labels = nothing, kwargs...)

Plot a topoplot.
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, Vector{Float32}}` \\
    Data for the plot visualization.
- `positions::Vector{Point{2, Float32}}`\\
    Positions used if `data` is not a `DataFrame`. Positions are generated from `labels` if `positions = nothing`.
- `labels::Vector{String} = nothing`\\
    Labels used if `data` is not a DataFrame.

$(_docstring(:topoplot))

**Return Value:** `Figure` displaying the Topoplot.
"""
plot_topoplot(data::Union{<:AbstractDataFrame,<:AbstractVector}; kwargs...) =
    plot_topoplot!(Figure(), data; kwargs...)

function plot_topoplot!(
    f::Union{GridPosition,GridLayout,GridLayoutBase.GridSubposition,Figure},
    data::Union{<:AbstractDataFrame,<:AbstractVector};
    labels = nothing,
    positions = nothing,
    kwargs...,
)
    config = PlotConfig(:topoplot)
    config_kwargs!(config; kwargs...) # potentially should be combined

    axis = Axis(f[1, 1]; config.axis...)

    if !(data isa Vector)
        config.mapping = resolve_mappings(data, config.mapping)
        data = data[:, config.mapping.y]
    end

    if isnothing(positions) && !isnothing(labels)
        positions = TopoPlots.labels2positions(labels)
    end
    positions = get_topo_positions(; positions = positions, labels = labels)
    eeg_topoplot!(axis, data, labels; positions, config.visual...)

    clims = (min(data...), max(data...))
    if clims[1] ≈ clims[2]
        @warn """The min and max of the value represented by the color are the same, it seems that the data values are identical. 
We disable the color bar in this figure.
Note: The identical min and max may cause an interpolation error when plotting the topoplot."""
        config_kwargs!(config, layout = (; use_colorbar = false, show_legend = false))
    else
        config_kwargs!(config, colorbar = (; limits = clims))
    end
    apply_layout_settings!(config; fig = f)

    return f
end

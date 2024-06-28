"""
    plot_topoplot!(f::Union{GridPosition, GridLayout, Figure}, data, ; positions = nothing, labels = nothing, kwargs...)
    plot_topoplot(data; positions = nothing, labels = nothing, kwargs...)

Plot a topoplot.
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, Vector{Float32}}` \\
    Data for the plot visualization.
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Positions used if `data` is not a `DataFrame`. Positions are generated from `labels` if `positions = nothing`.
- `labels::Vector{String} = nothing`\\
    Labels used if `data` is not a DataFrame.

$(_docstring(:topoplot))

**Return Value:** `Figure` displaying the Topoplot.
"""
plot_topoplot(data::Union{DataFrame,Vector{Float32}}; kwargs...) =
    plot_topoplot!(Figure(), data; kwargs...)


_topoplot_get_data(data::AbstractDataFrame,config) = @view data[:, config.mapping.y]
_topoplot_get_data(data::AbstractVector,config) =  data
_topoplot_get_data(data) = error("Input data need to be DataFrame or Vector")    
function plot_topoplot!(
    f::Union{GridPosition,GridLayout,Figure},
    data_input,
    positions = nothing,
    labels = nothing,
    kwargs...,
)
    config = PlotConfig(:topoplot)
    config_kwargs!(config; kwargs...) # potentially should be combined
    config.mapping = resolve_mappings(data, config.mapping)

    axis = Axis(f[1, 1]; config.axis...)

    # if data_input is a DataFrame, extract the column according to config.mapping.y
    data_for_topoplot = _topoplot_get_data(data_input,config)

    

    positions = get_topo_positions(; positions = positions, labels = labels)
    eeg_topoplot!(axis, data_for_topoplot, labels; positions, config.visual...)

    clims = (min(data_for_topoplot...), max(data_for_topoplot...))
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

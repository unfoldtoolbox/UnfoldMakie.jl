"""
    function plot_topoplot!(f::Union{GridPosition, Figure}, plotData, ; positions=nothing, labels=nothing,kwargs...)
    function plot_topoplot(plotData,; positions=nothing, labels=nothing,kwargs...)

Plot a topo plot.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition (e.g. f[2,3]) that the plot should be drawn into. new axis is created
- `plotData::Union{DataFrame, Vector{Float32}}`: Data for the plot visualization.
- `positions::Vector{Point{2, Float32}}=nothing`: positions used if `plotData` is no DataFrame. If this is the case and `positions=nothing` then positions is generated from `labels`.
- `labels::Vector{String}=nothing`: labels used if `plotData` is no DataFrame.

## Extra Data Behavior (...;setExtraValues=(;[key]=value)):
None

## Return Value:
A figure displaying the topo plot.
"""
plot_topoplot(plotData::Union{DataFrame,Vector{Float32}}; kwargs...) = plot_topoplot!(Figure(), plotData; kwargs...)
function plot_topoplot!(f::Union{GridPosition,Figure}, plotData::Union{DataFrame,<:AbstractVector}; positions=nothing, labels=nothing, kwargs...)
    config = PlotConfig(:topoplot)
    config_kwargs!(config; kwargs...) # potentially should be combined

    axis = Axis(f[1, 1]; aspect=DataAspect(), config.axis...)


    if !(plotData isa Vector)
        config.mapping = resolveMappings(plotData, config.mapping)
        plotData = plotData[:, config.mapping.y]
    end

    positions = getTopoPositions(; positions=positions, labels=labels)

    eeg_topoplot!(axis, plotData, labels; positions, config.visual...)

    config_kwargs!(config, colorbar=(; limits=(min(plotData...), max(plotData...))))
    applyLayoutSettings!(config; fig=f)

    return f
end

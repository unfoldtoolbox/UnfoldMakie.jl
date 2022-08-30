using AlgebraOfGraphics
using Makie
using DataFrames
using TopoPlots
using ColorSchemes


"""
    function plot_topo(plotData, config::PlotConfig; positions=nothing, labels=nothing)

Plot a topo plot.
## Arguments:
- `plotData`: Data for the plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
- `positions=nothing`: positions used if `plotData` is no DataFrame. If this is the case and `positions=nothing` then positions is generated from `lables`.
- `labels=nothing`: labels used if `plotData` is no DataFrame.

## Extra Data Behavior:
None

## Return Value:
A figure displaying the topo plot.
"""
function plot_topo(plotData, config::PlotConfig; positions=nothing, labels=nothing)
    plot_topo!(Figure(), plotData, config; positions, labels)
end

"""
    function plot_topo!(f::Union{GridPosition, Figure}, plotData, config::PlotConfig; positions=nothing, labels=nothing)

Plot a topo plot.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData`: Data for the plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
- `positions=nothing`: positions used if `plotData` is no DataFrame. If this is the case and `positions=nothing` then positions is generated from `lables`.
- `labels=nothing`: labels used if `plotData` is no DataFrame.

## Extra Data Behavior:
None

## Return Value:
A figure displaying the topo plot.
"""
function plot_topo!(f::Union{GridPosition, Figure}, plotData, config::PlotConfig; positions=nothing, labels=nothing)
    axis = Axis(f[1, 1]; config.axisData...)

    if plotData isa DataFrame
        config.resolveMappings(plotData)

        positions = getTopoPositions(plotData, config)
        labels = (string(config.mappingData.topoLabels) ∈ names(plotData)) ? plotData[:,config.mappingData.topoLabels] : nothing    
        plotData = plotData[:,config.mappingData.topodata]
    else
        if isnothing(positions)
            positions = (labels .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2])))
        end
    end

    if config.plotType == :eegtopoplot
        eeg_topoplot!(axis, plotData, labels; positions, config.visualData...)
    else
        topoplot!(axis, plotData, positions; labels, config.visualData...)
    end

    config.setColorbarValues(limits = (min(plotData...), max(plotData...)))

    applyLayoutSettings(config; fig=f)

    return f
end
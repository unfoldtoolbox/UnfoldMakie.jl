using AlgebraOfGraphics
using Makie
using DataFrames
using TopoPlots
using ColorSchemes


"""
    plot_topo(plotData, config::PlotConfig; positions=nothing, labels=nothing)

Plot a topo plot.
## Arguments:
- `plotData`: data for the topo plot being visualized.
- `config::PlotConfig`: data of the configuration being applied to the visualization.
- `positions=nothing`: positions used if `plotData` is no DataFrame. If this is the case and `positions=nothing` then positions is generated from `lables`.
- `labels=nothing`: labels used if `plotData` is no DataFrame.

## Behavior: TODO?
### `config.extraData.-`:

## Return Value:
The figure displaying the topo plot.
"""
function plot_topo(plotData, config::PlotConfig; positions=nothing, labels=nothing)
    plot_topo!(Figure(), plotData, config; positions, labels)
end

function plot_topo!(f::Union{GridPosition, Figure}, plotData, config::PlotConfig; positions=nothing, labels=nothing)
    axis = Axis(f[1, 1]; config.axisData...)

    if plotData isa DataFrame
        config.resolveMappings(plotData)

        if string(config.mappingData.positions) ∉ names(plotData)
            plotData[!,config.mappingData.positions] = plotData[!,config.mappingData.labels] .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2]))
        end
    
        labels = (string(config.mappingData.labels) ∈ names(plotData)) ? plotData[:,config.mappingData.labels] : nothing    
        positions = plotData[:,config.mappingData.positions]
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
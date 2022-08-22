using AlgebraOfGraphics
using Makie
using DataFrames
using ..PlotConfigs
using TopoPlots
using ColorSchemes


""" Plot TopoPlots  """
function plot_topo(config::PlotConfig, topodata; positions=nothing, labels=nothing)
    f = Figure()
    axis = Axis(f[1, 1])

    if topodata isa DataFrame
        if string(config.mappingData.positions) ∉ names(topodata)
            topodata[!,config.mappingData.positions] = topodata[!,config.mappingData.labels] .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2]))
        end
    
        labels = (string(config.mappingData.labels) ∈ names(topodata)) ? topodata[:,config.mappingData.labels] : nothing    
        positions = topodata[:,config.mappingData.positions]
        topodata = topodata[:,config.mappingData.topodata]
    else
        if isnothing(positions)
            positions = (labels .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2])))
        end
    end

    if config.plotType == :eegtopoplot
        eeg_topoplot!(axis, topodata, labels; positions, config.visualData...)
    else
        topoplot!(axis, topodata, positions; labels, config.visualData...)
    end

    config.setColorbarValues(limits = (min(topodata...), max(topodata...)))

    applyLayoutSettings(config; fig=f)

    return f
end
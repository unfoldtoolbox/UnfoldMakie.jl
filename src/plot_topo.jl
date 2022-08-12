using AlgebraOfGraphics
using Makie
using DataFrames
using ..PlotConfigs
using TopoPlots
using ColorSchemes


""" Plot TopoPlots  """
function plot_topo(config::PlotConfig, topodata; positions=nothing, labels=nothing)
    f = Figure()

    if isnothing(positions)
        positions = (labels .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2])))
    end

    if config.extraData.type == :eegtopoplot
        eeg_topoplot(f[1, 1], topodata, labels; positions, config.extraData...)
    else
        topoplot(f[1, 1], topodata, positions; labels, config.extraData...)
    end

    return f
end

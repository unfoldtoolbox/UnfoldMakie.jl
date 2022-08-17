using AlgebraOfGraphics
using Makie
using DataFrames
using ..PlotConfigs
using TopoPlots
using ColorSchemes
using Printf


""" Plot TopoPlots  """
function plot_topo(config::PlotConfig, topodata; positions=nothing, labels=nothing)
    f = Figure()
    axis = Axis(f[1, 1])

    if isnothing(positions)
        positions = (labels .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2])))
    end

    if config.extraData.type == :eegtopoplot
        drawing = eeg_topoplot!(axis, topodata, labels; positions, config.extraData...)
    else
        drawing = topoplot!(axis, topodata, positions; labels, config.extraData...)
    end

    applyLayoutSettings(config)

    return f
end

function plot_topo(config::PlotConfig, results::DataFrame=nothing)
    results = deepcopy(results)
    f = Figure()

    if string(config.visualData.positions) ∉ names(results)
        results[!,config.visualData.positions] = results[!,config.visualData.labels] .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2]))
    end

    topodata = results[:,config.visualData.topodata]
    positions = results[:,config.visualData.positions]
    labels = (string(config.visualData.labels) ∈ names(results)) ? results[:,config.visualData.labels] : nothing

    if config.extraData.type == :eegtopoplot
        eeg_topoplot(f[1, 1], topodata, labels; positions, config.extraData...)
    else
        topoplot(f[1, 1], topodata, positions; labels, config.extraData...)
    end

    applyLayoutSettings(config)

    return f
end

function applyLayoutSettings(config::PlotConfig; drawing = nothing)
    # remove border
    if !config.extraData.border
        hidespines!(current_axis(), :t, :r)
    end

    # set f[] position depending on position
    if (config.extraData.showLegend)
        if isnothing(drawing)
            @printf "Legends not supported for this Plot"
        else
            legendPosition = config.extraData.legendPosition == :right ? f[1, 2] : f[2, 1];

            legend!(legendPosition, drawing[1].val; config.legendData...)
            colorbar!(legendPosition, drawing[1].val; config.colorbarData...)
        end
    end
    
    # # label
    ax = current_axis()
    ax.xlabel = config.extraData.xlabel === nothing ? string(config.mappingData.x) : config.extraData.xlabel
    ax.ylabel = config.extraData.ylabel === nothing ? string(config.mappingData.y) : config.extraData.ylabel
end
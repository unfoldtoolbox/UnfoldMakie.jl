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

    if config.plotType == :eegtopoplot
        eeg_topoplot!(axis, topodata, labels; positions, config.visualData...)
    else
        topoplot!(axis, topodata, positions; labels, config.visualData...)
    end

    applyLayoutSettings(config; fig=f)

    return f
end

function plot_topo(config::PlotConfig, results::DataFrame=nothing)
    results = deepcopy(results)
    f = Figure()

    if string(config.mappingData.positions) ∉ names(results)
        results[!,config.mappingData.positions] = results[!,config.mappingData.labels] .|> (x -> Point2f(getLabelPos(x)[1], getLabelPos(x)[2]))
    end

    topodata = results[:,config.mappingData.topodata]
    positions = results[:,config.mappingData.positions]
    labels = (string(config.mappingData.labels) ∈ names(results)) ? results[:,config.mappingData.labels] : nothing

    if config.plotType == :eegtopoplot
        eeg_topoplot(f[1, 1], topodata, labels; positions, config.visualData...)
    else
        topoplot(f[1, 1], topodata, positions; labels, config.visualData...)
    end


    applyLayoutSettings(config; fig=f)

    return f
end

function applyLayoutSettings(config::PlotConfig; fig = nothing, drawing = nothing)
    # remove border
    if !config.extraData.border
        hidespines!(current_axis(), :t, :r)
    end

    # set f[] position depending on position
    if (config.extraData.showLegend)
        if isnothing(drawing)
            @printf "Legends not supported for this Plot"
            Colorbar(fig[1, 2]; config.colorbarData...)
            # Legend(fig[1, 2]; config.legendData...)
        else
            legendPosition = config.extraData.legendPosition == :right ? fig[1, 2] : fig[2, 1];

            legend!(legendPosition, drawing[1].val; config.legendData...)
            colorbar!(legendPosition, drawing[1].val; config.colorbarData...)
        end
    end
    
    # # label
    ax = current_axis()
    ax.xlabel = config.extraData.xlabel === nothing ? string(config.mappingData.x) : config.extraData.xlabel
    ax.ylabel = config.extraData.ylabel === nothing ? string(config.mappingData.y) : config.extraData.ylabel
end
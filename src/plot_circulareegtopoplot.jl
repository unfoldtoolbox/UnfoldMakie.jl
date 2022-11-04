# needing a config object in method defintion for the case where config is not given
tempConfig = PlotConfig(:circeegtopo)

#plotData consists of the plot's data in index 1 and 2 and index 3 being the predictor values
plot_circulareegtopoplot(plotData, config::PlotConfig;kwargs...) = plot_circulareegtopoplot!(Figure(backgroundcolor = config.axisData.backgroundcolor, resolution = (1000, 1000)), plotData, config;kwargs...)
plot_circulareegtopoplot(plotData;kwargs...) = plot_circulareegtopoplot!(Figure(backgroundcolor = tempConfig.axisData.backgroundcolor, resolution = (1000, 1000)), plotData, tempConfig;kwargs...)
function plot_circulareegtopoplot!(fig, plotData, config::PlotConfig;kwargs...)
    # fig could also be of type GridLayout or GridPosition which is a child of Figure
    f = fig
    while typeof(f) != Figure
        f = f.parent
    end
    resolution = f.scene.px_area.val.widths.data
    
    # moving the values of the predictor to a different array to perform boolean queries on them
    predictorValues = plotData[2]

    if(length(config.extraData.predictorBounds) != 2) 
        error("the predictorBounds vector needs exactly two values")
    end
    if(config.extraData.predictorBounds[1] >= config.extraData.predictorBounds[2])
        error("config.extraData.predictorBounds[1] needs to be smaller than config.extraData.predictorBounds[2]")
    end
    if((length(predictorValues[predictorValues .< config.extraData.predictorBounds[1]]) != 0) || (length(predictorValues[predictorValues .> config.extraData.predictorBounds[2]]) != 0))
        error("all values in plotData[2] have to be within the config.extraData.predictorBounds range")
    end
    if(length(plotData[1]) != length(plotData[2]))
        error("plotData and plotData[2] have to be of the same size")
    end
    if(length(plotData[1]) != length(config.extraData.topoplotLabels))
        error("plotData[1] and config.extraData.topoplotLabels have to be of the same size")
    end

    plotCircularAxis(f, config.extraData.predictorBounds,config.axisData.label, config.axisData.backgroundcolor)

    min, max = calculateGlobalMaxValues(plotData[1])

    plotTopoPlots(f, resolution, config.axisData.backgroundcolor,plotData[1], config.extraData.topoplotLabels, predictorValues, config.extraData.predictorBounds, min, max)
    Colorbar(f, bbox = BBox(resolution[1]*0.8,resolution[1]*0.9,resolution[2]*0.05,resolution[2]*0.2), colormap = config.colorbarData.colormap, colorrange=(min, max), label = config.colorbarData.label)
    
    applyLayoutSettings(config; fig=f)
    # set the scene's background color according to config
    set_theme!(Theme(backgroundcolor = config.axisData.backgroundcolor))
    return f
end

function calculateGlobalMaxValues(plotData)
    globalMaxVal = 0

    for (index, value) in enumerate(plotData)
        datapoints = value[1]
        datapoints1d = vec(copy(datapoints))
        localMaxVal = maximum(abs.(quantile!(datapoints1d, [0.01,0.99])))
        if(localMaxVal > globalMaxVal)
            globalMaxVal = localMaxVal
        end
    end
    return (-globalMaxVal,globalMaxVal)
end

function plotCircularAxis(f, predictorBounds, label, bgcolor)
    # the axis position is always the middle of the screen (means it uses the GridLayout's full size)
    circleAxis = Axis(f[1:f.layout.size[1],1:f.layout.size[2]], aspect = 1, backgroundcolor = bgcolor)
    xlims!(-9,9)
    ylims!(-9,9)
    hidedecorations!(circleAxis)
    hidespines!(circleAxis)
    lines!(circleAxis, 3 * cos.(LinRange(0,2*pi,500)), 3 * sin.(LinRange(0,2*pi,500)), color = (:black, 0.5),linewidth = 3)

    # labels and label lines for the circle
    circlepoints_lines = [(3.2 * cos(a), 3.2 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    circlepoints_labels = [(3.6 * cos(a), 3.6 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    text!(
        circlepoints_lines,
        # using underscores as lines around the circular axis
        text = ["_","_","_","_"],
        rotation = LinRange(0, 2pi, 5)[1:end-1],
        align = (:right, :baseline),
        textsize = 30
    )
    text!(
        circlepoints_labels,
        text = calculateAxisLabels(predictorBounds),
        align = (:center, :center),
        textsize = 30
    )
    text!(circleAxis, 0, 0, text = label, align = (:center, :center),textsize = 40)
end

# four labels around the circle, middle values are the 0.25, 0.5, and 0.75 quantiles
function calculateAxisLabels(predictorBounds)
    nonboundlabels = quantile(predictorBounds,[0.25,0.5,0.75])
    # third label is on the left and it tends to cover the circle so added some blank spaces to tackle that
    return [string(trunc(Int,predictorBounds[1])), string(trunc(Int,nonboundlabels[1])), string(trunc(Int,nonboundlabels[2]), "   "), string(trunc(Int,nonboundlabels[3]))]
end

function plotTopoPlots(f, configResolution, configBackgroundColor, data, topoplotLabels, predictorValues, predictorBounds, globalmin, globalmax)
    for (index, value) in enumerate(data)
        datapoints, positions = value
        eegaxis = Axis(f, bbox = calculateBBoxCoordiantes(configResolution,predictorValues[index],predictorBounds), backgroundcolor = configBackgroundColor)
        hidedecorations!(eegaxis)
        hidespines!(eegaxis)
        TopoPlots.eeg_topoplot!(datapoints[:, 340, 1], eegaxis, topoplotLabels[index]; positions=positions, colorrange = (globalmin, globalmax))
    end
end

function calculateBBoxCoordiantes(configResolution, predictorValue, bounds)
    canvasResolution = minimum(configResolution)
    percentage = (predictorValue-bounds[1])/(bounds[2]-bounds[1])
    radius = (canvasResolution * 0.7) / 2
    sizeOfBBox = canvasResolution / 5

    # the middle point of the circle for the topoplot positions
    # has to be moved a bit into the direction of the longer axis
    # to be centered on a scene that's not shaped like a square
    resShift = [(configResolution[1] - configResolution[2]) / 2, (configResolution[2] - configResolution[1]) / 2]
    resShift[resShift .< 0] .= 0
    x = radius*cos(percentage*2*pi) + resShift[1]
    y = radius*sin(percentage*2*pi) + resShift[2]
    
    return BBox(canvasResolution/2-sizeOfBBox/2 + x, canvasResolution/2+sizeOfBBox-sizeOfBBox/2 + x, canvasResolution/2-sizeOfBBox/2 + y, canvasResolution/2+sizeOfBBox-sizeOfBBox/2 + y)
end


# uncomment this to try out the functions
#data = TopoPlots.example_data()
#labels = ["s$i" for i in 1:size(data, 1)]

#f = Figure(resolution = (700,1500))
#Axis(f[1,1])
#Axis(f[1,3])
#g = f[1,2] = GridLayout()
#plot_circulareegtopoplot!(g,([data,data,data,data,data,data],[0,50,80,120,180,210]),tempConfig)
#f
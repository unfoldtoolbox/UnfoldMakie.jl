# needing a config object in method defintion for the case where config is not given
tempConfig = PlotConfig(:circeegtopo)

"""
    function plot_circulareegtopoplot(plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}}, config::PlotConfig;kwargs...) = plot_circulareegtopoplot!(Figure(backgroundcolor = config.axisData.backgroundcolor, resolution = (1000, 1000)), plotData, config;kwargs...)
    function plot_circulareegtopoplot(plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}};kwargs...) = plot_circulareegtopoplot!(Figure(backgroundcolor = tempConfig.axisData.backgroundcolor, resolution = (1000, 1000)), plotData, tempConfig;kwargs...)
    function plot_circulareegtopoplot!(f_in, plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}}, config::PlotConfig;kwargs...)

        

Plot a circular EEG topoplot.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}}`: Vector of data for each topoplot used in this plot, and the predictor values. Each topoplot data element in that vecotr is a vector of an nChannels x 1 vector containing yhat values, and an nchannels x 1 vector containing points that represent the electrode's location on the topoplot
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
- `kwargs...`: Additional styling behavior.
## Extra Data Behavior (...;setExtraValues=(;[key]=value)):
topoplotLabel = ["s1","s2"],
                predictorBounds = [0,360],
`topoplotLabel`:

Default : `["s1","s2"]

Channel labels of the topoplot

`predictorBounds`:

Default: `[0,360]`

The bounds of the predictor. This is relevant for the axis labels.

## Return Value:
The input `f`

"""
plot_circulareegtopoplot(plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}}, config::PlotConfig;kwargs...) = plot_circulareegtopoplot!(Figure(backgroundcolor = config.axisData.backgroundcolor, resolution = (1000, 1000)), plotData, config;kwargs...)
plot_circulareegtopoplot(plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}};kwargs...) = plot_circulareegtopoplot!(Figure(backgroundcolor = tempConfig.axisData.backgroundcolor, resolution = (1000, 1000)), plotData, tempConfig;kwargs...)
function plot_circulareegtopoplot!(f_in, plotData::Tuple{Vector{Tuple{Vector{Number}, Vector{Point{2, Number}}}}, Vector{Number}}, config::PlotConfig;kwargs...)

    # notice that this method handles cases in which f_in is of type Figure, GridLayout, GridPosition, and GridSubposition
    f_in_pos = f_in
    nestedPositions = DataStructures.Stack{Array{Int}}()
    while(typeof(f_in_pos) == GridSubposition)
        nestedPositions = DataStructures.push!(nestedPositions,[f_in_pos.rows,f_in_pos.cols])
        f_in_pos = f_in_pos.parent
    end

    f = (typeof(f_in_pos) == GridPosition) ? f_in_pos.layout.parent[f_in_pos.span.rows,f_in_pos.span.cols] = GridLayout() : f_in_pos
    while(!isempty(nestedPositions))
        index = DataStructures.pop!(nestedPositions)
        f = f[index[1],index[2]] = GridLayout()
    end

    # f could also be of type GridLayout or GridPosition
    sugbboxval = (typeof(f) == Figure) ? f.layout.layoutobservables.suggestedbbox.val : f.layoutobservables.suggestedbbox.val
    origin = sugbboxval.origin
    widths = sugbboxval.widths
    
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
        error("plotData[1] and plotData[2] have to be of the same length")
    end

    plotCircularAxis(f, origin, widths, config.extraData.predictorBounds,config.axisData.label, config.axisData.backgroundcolor)

    min, max = calculateGlobalMaxValues(plotData[1])

    # bboxes cannot be applied to GridLayout or GridPosition objects, only to their parent Figure object
    fig = f
    # GridLayout and GridPosition can be subchildren of figures
    while typeof(fig) != Figure
        fig = fig.parent
    end

    plotTopoPlots(f, fig, origin, widths, config.axisData.backgroundcolor,plotData[1], config.extraData.topoplotLabel, predictorValues, config.extraData.predictorBounds, min, max)
    # setting the colorbar to the bottom right of the box.
    # Relative values got determined by checking what subjectively
    # looks best
    Colorbar(fig, bbox = BBox((origin[1]+widths[1])*0.85,(origin[1]+widths[1])*0.95,(origin[2]+widths[2])*0.06,(origin[2]+widths[2])*0.25), colormap = config.colorbarData.colormap, colorrange=(min, max), label = config.colorbarData.label)
    
    applyLayoutSettings(config; fig=f)
    # set the scene's background color according to config
    set_theme!(Theme(backgroundcolor = config.axisData.backgroundcolor))
    return f
end

function calculateGlobalMaxValues(plotData)
    globalMaxVal = 0

    for (index, value) in enumerate(plotData)
        datapoints = copy(value[1])
        localMaxVal = maximum(abs.(quantile!(datapoints, [0.01,0.99])))
        if(localMaxVal > globalMaxVal)
            globalMaxVal = localMaxVal
        end
    end
    return (-globalMaxVal,globalMaxVal)
end

function plotCircularAxis(f, origin, widths, predictorBounds, label, bgcolor)
    # the axis position is always the middle of the
    # screen (means it uses the GridLayout's full size)
    circleAxis = typeof(f) == Figure ? Axis(f[1:f.layout.size[1],1:f.layout.size[2]], aspect = 1, backgroundcolor = bgcolor) : Axis(f[1,1], aspect = 1, backgroundcolor = bgcolor)
    xlims!(-9,9)
    ylims!(-9,9)
    hidedecorations!(circleAxis)
    hidespines!(circleAxis)
    lines!(circleAxis, 3 * cos.(LinRange(0,2*pi,500)), 3 * sin.(LinRange(0,2*pi,500)), color = (:black, 0.5),linewidth = 3)

    minsize = minimum([origin[1]+widths[1],origin[2]+widths[2]])

    # labels and label lines for the circle
    circlepoints_lines = [(3.2 * cos(a), 3.2 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    circlepoints_labels = [(3.6 * cos(a), 3.6 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    text!(
        circlepoints_lines,
        # using underscores as lines around the circular axis
        text = ["_","_","_","_"],
        rotation = LinRange(0, 2pi, 5)[1:end-1],
        align = (:right, :baseline),
        textsize = round(minsize*0.03)
    )
    text!(
        circlepoints_labels,
        text = calculateAxisLabels(predictorBounds),
        align = (:center, :center),
        textsize = round(minsize*0.03)
    )
    text!(circleAxis, 0, 0, text = label, align = (:center, :center),textsize = round(minsize*0.04))
end

# four labels around the circle, middle values are the 0.25, 0.5, and 0.75 quantiles
function calculateAxisLabels(predictorBounds)
    nonboundlabels = quantile(predictorBounds,[0.25,0.5,0.75])
    # third label is on the left and it tends to cover the circle
    # so added some blank spaces to tackle that
    return [string(trunc(Int,predictorBounds[1])), string(trunc(Int,nonboundlabels[1])), string(trunc(Int,nonboundlabels[2]), "   "), string(trunc(Int,nonboundlabels[3]))]
end

function plotTopoPlots(f, fig, origin, widths, configBackgroundColor, data, topoplotLabel, predictorValues, predictorBounds, globalmin, globalmax)
    for (index, value) in enumerate(data)
        datapoints, positions = value
        bbox = calculateBBox(origin, widths, predictorValues[index],predictorBounds)
        eegaxis = Axis(fig, bbox = bbox, backgroundcolor = configBackgroundColor)
        hidedecorations!(eegaxis)
        hidespines!(eegaxis)
        TopoPlots.eeg_topoplot!(datapoints, eegaxis, topoplotLabel; positions=positions, colorrange = (globalmin, globalmax))
    end
end

function calculateBBox(origin, widths, predictorValue, bounds)
    minwidth = minimum(widths)
    predictorRatio = (predictorValue-bounds[1])/(bounds[2]-bounds[1])
    radius = (minwidth * 0.7) / 2
    sizeOfBBox = minwidth / 5

    # the middle point of the circle for the topoplot positions
    # has to be moved a bit into the direction of the longer axis
    # to be centered on a scene that's not shaped like a square
    resShift = [((origin[1] + widths[1]) - widths[1]) / 2, ((origin[2] + widths[2]) - widths[2]) / 2]
    resShift[resShift .< 0] .= 0

    x = radius * cos(predictorRatio * 2 * pi) + resShift[1]
    y = radius * sin(predictorRatio * 2 * pi) + resShift[2]
    
    # notice that the bbox defines the bottom left and the top
    # right point of the axis. This means that you have to 
    # move the bbox to the bottom left by sizeofbbox/2 to move
    # the center of the axis to a point 
    return BBox((origin[1]+widths[1]) / 2 - sizeOfBBox / 2 + x, (origin[1]+widths[1]) / 2 + sizeOfBBox - sizeOfBBox / 2 + x, (origin[2]+widths[2]) / 2 - sizeOfBBox / 2 + y, (origin[2]+widths[2]) / 2 + sizeOfBBox - sizeOfBBox / 2 + y)
end


# uncomment everything below this to try out the code
#data = (TopoPlots.example_data()[1][:, 340, 1],data[2])
#f = Figure(resolution = (1000,1000))
#plot_circulareegtopoplot!(f,([data,data,data,data,data,data],[0,50,80,120,180,210]),tempConfig)
#f
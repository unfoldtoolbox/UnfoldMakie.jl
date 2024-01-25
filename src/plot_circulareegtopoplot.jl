"""
    plot_circulareegtopoplot!(f, data::DataFrame; kwargs...)
    plot_circulareegtopoplot(data::DataFrame; kwargs...)
    

Plot a circular EEG topoplot.
## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`: Figure, GridLayout or GridPosition that the plot should be drawn into
- `data::DataFrame`: DataFrame with keys for data (looks for `:y, :yhat, :estimate`), and :position (looks for `:pos, :position, :positions`), 
- `predictor` (optional; default: `predictor`): the circular predictor value, defines position of topoplot, is mapped around `predictor_bounds`
- `predictor_bounds` (default: `[0,360]`): the bounds of the predictor. This is relevant for the axis labels.
- `positions` (default: `nothing`): positions for the [`plot_topoplot`](@Ref)
- `center_label` (default: ""): the text in the center of the cricle
- `labels` (default: `nothing`): labels for the [`plot_topoplot`](@Ref)

- `kwargs...`: additional styling behavior, see below.


$(_docstring(:circeegtopo))



## Return Value:
A figure containing the circular topoplot at given layout position

"""
plot_circulareegtopoplot(data::DataFrame; kwargs...) =
    plot_circulareegtopoplot!(Figure(), data; kwargs...)
plot_circulareegtopoplot!(f, data::DataFrame; kwargs...) =
    plot_circulareegtopoplot!(f, data; kwargs...)
function plot_circulareegtopoplot!(
    f::Union{GridPosition,GridLayout,Figure},
    data::DataFrame;
    predictor = :predictor,
    predictor_bounds = [0, 360],
    positions = nothing,
    labels = nothing,
    center_label = "",
    kwargs...,
)
    config = PlotConfig(:circeegtopo)
    config_kwargs!(config; kwargs...)
    config.mapping = resolve_mappings(data, config.mapping)


    positions = getTopoPositions(; positions = positions, labels = labels)
    # moving the values of the predictor to a different array to perform boolean queries on them
    predictorValues = data[:, predictor]

    if (length(predictor_bounds) != 2)
        error("predictor_bounds needs exactly two values")
    end
    if (predictor_bounds[1] >= predictor_bounds[2])
        error(
            "predictor_bounds[1] needs to be smaller than predictor_bounds[2]",
        )
    end
    if (
        (length(predictorValues[predictorValues.<predictor_bounds[1]]) != 0) ||
        (length(predictorValues[predictorValues.>predictor_bounds[2]]) != 0)
    )
        error(
            "all values in the data's effect column have to be within the predictor_bounds range",
        )
    end
    if (all(predictorValues .<= 2 * pi))
        @warn "insert the predictor values in degrees instead of radian, or change predictor_bounds"
    end

    ax = Axis(f[1, 1]; aspect = 1)

    hidedecorations!(ax)
    hidespines!(ax)

    plotCircularAxis!(ax, predictor_bounds, center_label)
    limits!(ax, -3.5, 3.5, -3.5, 3.5)
    min, max = calculateGlobalMaxValues(data[:, config.mapping.y], predictorValues)

    positions = getTopoPositions(; positions = positions, labels = labels)
    plotTopoPlots!(
        ax,
        data[:, config.mapping.y],
        positions,
        predictorValues,
        predictor_bounds,
        min,
        max,
    )
    # setting the colorbar to the bottom right of the box.
    # Relative values got determined by checking what subjectively
    # looks best
    #RelativeAxis(ax,(0.85,0.95,0.06,0.25))
    Colorbar(
        f[1, 2],
        colormap = config.colorbar.colormap,
        colorrange = (min, max),
        label = config.colorbar.label,
        height = @lift Fixed($(pixelarea(ax.scene)).widths[2])
    )
    apply_layout_settings!(config; ax = ax)

    # set the scene's background color according to config
    #set_theme!(Theme(backgroundcolor = config.axisData.backgroundcolor))
    return f
end

function calculateGlobalMaxValues(data, predictor)

    x = combine(
        groupby(DataFrame(:e => data, :p => predictor), :p),
        :e => (x -> maximum(abs.(quantile!(x, [0.01, 0.99])))) => :localMaxVal,
    )


    globalMaxVal = round(maximum(x.localMaxVal), digits = 2)
    return (-globalMaxVal, globalMaxVal)
end

function plotCircularAxis!(ax, predictor_bounds, label)
    # the axis position is always the middle of the
    # screen (means it uses the GridLayout's full size)
    #circleAxis = Axis(f,aspect = 1)#typeof(f) == Figure ? Axis(f[1:f.layout.size[1],1:f.layout.size[2]], aspect = 1, backgroundcolor = bgcolor) : Axis(f[1,1], aspect = 1, backgroundcolor = bgcolor)
    #xlims!(-9,9)
    #ylims!(-9,9)

    lines!(
        ax,
        1 * cos.(LinRange(0, 2 * pi, 500)),
        1 * sin.(LinRange(0, 2 * pi, 500)),
        color = (:black, 0.5),
        linewidth = 3,
    )

    #minsize = minimum([origin[1]+widths[1],origin[2]+widths[2]])

    # labels and label lines for the circle
    circlepoints_lines =
        [(1.1 * cos(a), 1.1 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    circlepoints_labels =
        [(1.3 * cos(a), 1.3 * sin(a)) for a in LinRange(0, 2pi, 5)[1:end-1]]
    text!(
        circlepoints_lines,
        # using underscores as lines around the circular axis
        text = ["_", "_", "_", "_"],
        rotation = LinRange(0, 2pi, 5)[1:end-1],
        align = (:right, :baseline),
        #textsize = round(minsize*0.03)
    )
    text!(
        circlepoints_labels,
        text = calculateAxisLabels(predictor_bounds),
        align = (:center, :center),
        #textsize = round(minsize*0.03)
    )
    text!(ax, 0, 0, text = label, align = (:center, :center))#,textsize = round(minsize*0.04))

end

# four labels around the circle, middle values are the 0.25, 0.5, and 0.75 quantiles
function calculateAxisLabels(predictor_bounds)
    nonboundlabels = quantile(predictor_bounds, [0.25, 0.5, 0.75])
    # third label is on the left and it tends to cover the circle
    # so added some blank spaces to tackle that
    return [
        string(trunc(Int, predictor_bounds[1])),
        string(trunc(Int, nonboundlabels[1])),
        string(trunc(Int, nonboundlabels[2]), "   "),
        string(trunc(Int, nonboundlabels[3])),
    ]
end

function plotTopoPlots!(
    f,
    data,
    positions,
    predictorValues,
    predictor_bounds,
    globalmin,
    globalmax,
)
    #for (index, datapoints) in enumerate(data)
    df = DataFrame(:e => data, :p => predictorValues)
    gp = groupby(df, :p)
    for g in gp

        bbox = calculateBBox([0, 0], [1, 1], g.p[1], predictor_bounds)

        # convet BBox to rect
        rect = (
            Float64.([
                bbox.origin[1],
                bbox.origin[1] + bbox.widths[1],
                bbox.origin[2],
                bbox.origin[2] + bbox.widths[2],
            ])...,
        )


        eegaxis = RelativeAxis(f, rect; aspect = 1)

        TopoPlots.eeg_topoplot!(
            eegaxis,
            g.e;
            positions = positions,
            colorrange = (globalmin, globalmax),
            enlarge = 1,
        )
        hidedecorations!(eegaxis)
        hidespines!(eegaxis)


    end
end

function calculateBBox(origin, widths, predictorValue, bounds)

    minwidth = minimum(widths)
    predictorRatio = (predictorValue - bounds[1]) / (bounds[2] - bounds[1])
    radius = (minwidth * 0.7) / 2
    sizeOfBBox = minwidth / 5
    # the middle point of the circle for the topoplot positions
    # has to be moved a bit into the direction of the longer axis
    # to be centered on a scene that's not shaped like a square
    resShift = [
        ((origin[1] + widths[1]) - widths[1]) / 2,
        ((origin[2] + widths[2]) - widths[2]) / 2,
    ]
    resShift[resShift.<0] .= 0

    x = radius * cos(predictorRatio * 2 * pi) + resShift[1]
    y = radius * sin(predictorRatio * 2 * pi) + resShift[2]


    # notice that the bbox defines the bottom left and the top
    # right point of the axis. This means that you have to 
    # move the bbox to the bottom left by sizeofbbox/2 to move
    # the center of the axis to a point 
    return BBox(
        (origin[1] + widths[1]) / 2 - sizeOfBBox / 2 + x,
        (origin[1] + widths[1]) / 2 + sizeOfBBox - sizeOfBBox / 2 + x,
        (origin[2] + widths[2]) / 2 - sizeOfBBox / 2 + y,
        (origin[2] + widths[2]) / 2 + sizeOfBBox - sizeOfBBox / 2 + y,
    )
end


# uncomment everything below this to try out the code
#data,pos = TopoPlots.example_data();
#df= (DataFrame(    :effect=>Float64.([dat;dat;dat;dat;dat;dat]),    :predictor=>repeat([0,50,80,120,180,210],inner=length(dat)),    :positions=>repeat(pos,6)))
#plot_circulareegtopoplot!(df)

"""
    plot_circular_topoplots!(f, data::DataFrame; kwargs...)
    plot_circular_topoplots(data::DataFrame; kwargs...)

Plot a circular EEG topoplot.
## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.\\
- `data::DataFrame`\\
    DataFrame with data keys (columns `:y, :yhat, :estimate`), and :position (columns `:pos, :position, :positions`).

## Keyword arguments (kwargs)
- `predictor::Vector{Any} = :predictor`\\
    The circular predictor value, defines position of topoplot across the circle.
    Mapped around `predictor_bounds`.
- `predictor_bounds::Vector{Int64} = [0, 360]`\\
    The bounds of the predictor. Relevant for the axis labels.
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Positions of the [`plot_topoplot`](@ref topo_vis).
- `center_label::String = ""`\\
    The text in the center of the cricle.
- `plot_radius::String = 0.8`\\
    The radius of the circular topoplot series plot calucalted by formula: `radius = (minwidth * plot_radius) / 2`.
- `labels::Vector{String} = nothing`\\
    Labels for the [`plot_topoplots`](@ref topo_vis).

$(_docstring(:circtopos))

**Return Value:** `Figure` displaying the Circular topoplot series.

"""
plot_circular_topoplots(data::DataFrame; kwargs...) =
    plot_circular_topoplots!(Figure(), data; kwargs...)
plot_circular_topoplots!(f, data::DataFrame; kwargs...) =
    plot_circular_topoplots!(f, data; kwargs...)
function plot_circular_topoplots!(
    f::Union{GridPosition,GridLayout,Figure},
    data::DataFrame;
    predictor = :predictor,
    predictor_bounds = [0, 360],
    positions = nothing,
    labels = nothing,
    center_label = "",
    plot_radius = 0.8,
    kwargs...,
)
    config = PlotConfig(:circtopos)
    config_kwargs!(config; kwargs...)
    config.mapping = resolve_mappings(data, config.mapping)

    positions = get_topo_positions(; positions = positions, labels = labels)
    # moving the values of the predictor to a different array to perform boolean queries on them
    predictor_values = data[:, predictor]

    if (length(predictor_bounds) != 2)
        error("predictor_bounds needs exactly two values")
    end
    if (predictor_bounds[1] >= predictor_bounds[2])
        error("predictor_bounds[1] needs to be smaller than predictor_bounds[2]")
    end
    if (
        (length(predictor_values[predictor_values.<predictor_bounds[1]]) != 0) ||
        (length(predictor_values[predictor_values.>predictor_bounds[2]]) != 0)
    )
        error(
            "all values in the data's effect column have to be within the predictor_bounds range",
        )
    end
    if (all(predictor_values .<= 2 * pi))
        @warn "insert the predictor values in degrees instead of radian, or change predictor_bounds"
    end

    ax = Axis(f[1, 1]; aspect = 1)

    hidedecorations!(ax)
    hidespines!(ax)

    plot_circular_axis!(ax, predictor_bounds, center_label)
    limits!(ax, -3.5, 3.5, -3.5, 3.5)
    min, max = calculate_global_max_values(data[:, config.mapping.y], predictor_values)

    # setting the colorbar to the bottom right of the box.
    # Relative values got determined by checking what subjectively looks best 
    Colorbar(
        f[1, 2];
        colorrange = (min, max),
        config.colorbar...,
        height = @lift Fixed($(pixelarea(ax.scene)).widths[2])
    )
    plot_topo_plots!(
        f[1, 1],
        data[:, config.mapping.y],
        positions,
        predictor_values,
        predictor_bounds,
        min,
        max,
        labels,
        plot_radius,
    )

    apply_layout_settings!(config; ax = ax)
    # set the scene's background color according to config
    return f
end

function calculate_global_max_values(data, predictor)
    x = combine(
        groupby(DataFrame(:e => data, :p => predictor), :p),
        :e => (x -> maximum(abs.(quantile!(x, [0.01, 0.99])))) => :local_max_val,
    )
    global_max_val = maximum(x.local_max_val)
    return (-global_max_val, global_max_val)
end

function plot_circular_axis!(ax, predictor_bounds, center_label)
    # The axis position is always the middle of the screen 
    # It uses the GridLayout's full size
    lines!(
        ax,
        1 * cos.(LinRange(0, 2 * pi, 500)),
        1 * sin.(LinRange(0, 2 * pi, 500)),
        color = (:black, 0.5),
        linewidth = 3,
    )

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
        text = calculate_axis_labels(predictor_bounds),
        align = (:center, :center),
        #textsize = round(minsize*0.03)
    )
    text!(ax, 0, 0, text = center_label, align = (:center, :center)) #,textsize = round(minsize*0.04))
end

# four labels around the circle, middle values are the 0.25, 0.5, and 0.75 quantiles
function calculate_axis_labels(predictor_bounds)
    nonboundlabels = quantile(predictor_bounds, [0.25, 0.5, 0.75])
    # third label is on the left and it tends to cover the circle
    # so added some blank spaces to tackle that

    if typeof(predictor_bounds[1]) == Float64
        res = [
            string(trunc(predictor_bounds[1], digits = 1)),
            string(trunc(nonboundlabels[1], digits = 1)),
            string(trunc(nonboundlabels[2], digits = 1)),
            string(trunc(nonboundlabels[3], digits = 1)),
        ]

    else
        res = [
            string(trunc(Int, predictor_bounds[1])),
            string(trunc(Int, nonboundlabels[1])),
            string(trunc(Int, nonboundlabels[2]), " "),
            string(trunc(Int, nonboundlabels[3])),
        ]
    end
    return res
end

function plot_topo_plots!(
    f,
    data,
    positions,
    predictor_values,
    predictor_bounds,
    globalmin,
    globalmax,
    labels,
    plot_radius,
)
    df = DataFrame(:e => data, :p => predictor_values)
    gp = groupby(df, :p)
    i = 0
    for g in gp
        i += 1
        bbox = calculate_BBox([0, 0], [1, 1], g.p[1], predictor_bounds, plot_radius)
        eeg_axis = Axis(
            f, # this creates an axis at the same grid location of the current axis
            aspect = 1,
            width = Relative(0.2), # size of bboxes
            height = Relative(0.2), # size of bboxes
            halign = bbox.origin[1] + bbox.widths[1] / 2, # coordinates 
            valign = bbox.origin[2] + bbox.widths[2] / 2,
            #backgroundcolor = nothing,
        )

        if !isnothing(labels)
            eeg_axis.xlabel = labels[i]
        end

        TopoPlots.eeg_topoplot!(
            eeg_axis,
            g.e;
            positions = positions,
            colorrange = (globalmin, globalmax),
            enlarge = 1,
        )
        hidedecorations!(eeg_axis, label = false)
        hidespines!(eeg_axis)
    end
end

function calculate_BBox(origin, widths, predictor_value, bounds, plot_radius)
    minwidth = minimum(widths)
    predictor_ratio = (predictor_value - bounds[1]) / (bounds[2] - bounds[1])
    radius = (minwidth * plot_radius) / 2 # radius of the position circle of a circular topoplot 
    size_of_BBox = minwidth / 5
    # the middle point of the circle for the topoplot positions
    # has to be moved a bit into the direction of the longer axis
    # to be centered on a scene that's not shaped like a square.
    res_shift = [
        ((origin[1] + widths[1]) - widths[1]) / 2,
        ((origin[2] + widths[2]) - widths[2]) / 2,
    ]
    res_shift[res_shift.<0] .= 0

    x = radius * cos(predictor_ratio * 2 * pi) + res_shift[1]
    y = radius * sin(predictor_ratio * 2 * pi) + res_shift[2]

    # notice that the bbox defines the bottom left and the top
    # right point of the axis. This means that you have to 
    # move the bbox to the bottom left by size_of_bbox/2 to move
    # the center of the axis to a point. 
    if abs(y) < 1
        y = round(y, digits = 2)
    end
    return BBox(
        (origin[1] + widths[1]) / 2 - size_of_BBox / 2 + x,
        (origin[1] + widths[1]) / 2 + size_of_BBox - size_of_BBox / 2 + x,
        (origin[2] + widths[2]) / 2 - size_of_BBox / 2 + y,
        (origin[2] + widths[2]) / 2 + size_of_BBox - size_of_BBox / 2 + y,
    )
end

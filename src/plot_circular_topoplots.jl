"""
    plot_circular_topoplots!(f, data::DataFrame; kwargs...)
using DocStringExtensions: print_mutable_struct_or_struct
    plot_circular_topoplots(data::DataFrame; kwargs...)

Plot a circular EEG topoplot.
## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.\\
- `data::DataFrame`\\
    DataFrame with data keys (columns `:y, :yhat, :estimate`), and :position (columns `:pos, :position, :positions`).

## Keyword argumets (kwargs)
- `predictor::Vector{Any} = :predictor`\\
    The circular predictor value, defines position of topoplot across the circle.
    Mapped around `predictor_bounds`.
- `predictor_bounds::Vector{Int64} = [0, 360]`\\
    The bounds of the predictor. Relevant for the axis labels.
- `positions::Vector{Point{2, Float32}} = nothing`\\
    Positions of the [`plot_topoplot`](@ref topo_vis).
- `center_label::String = ""`\\
    The text in the center of the cricle.
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
    kwargs...,
)
    config = PlotConfig(:circtopos)
    config_kwargs!(config; kwargs...)
    config.mapping = resolve_mappings(data, config.mapping)

    positions = getTopoPositions(; positions = positions, labels = labels)
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

    plot_topo_plots!(
        ax,
        data[:, config.mapping.y],
        positions,
        predictor_values,
        predictor_bounds,
        min,
        max,
        labels,
    )
    # setting the colorbar to the bottom right of the box.
    # Relative values got determined by checking what subjectively looks best

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
    return [
        string(trunc(Int, predictor_bounds[1])),
        string(trunc(Int, nonboundlabels[1])),
        string(trunc(Int, nonboundlabels[2]), "   "),
        string(trunc(Int, nonboundlabels[3])),
    ]
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
)
    df = DataFrame(:e => data, :p => predictor_values)
    gp = groupby(df, :p)
    i = 0
    for g in gp
        i += 1
        bbox = calculate_BBox([0, 0], [1, 1], g.p[1], predictor_bounds)

        # convert BBox to rect
        rect = (
            Float64.([
                bbox.origin[1],
                bbox.origin[1] + bbox.widths[1],
                bbox.origin[2],
                bbox.origin[2] + bbox.widths[2],
            ])...,
        )

        eeg_axis = RelativeAxis(f, rect; xlabel = labels[i], aspect = 1)
        #= b = rel_to_abs_bbox(f.scene.viewport[] - 15, rect)
        eeg_axis = Axis(
            get_figure(f);
            bbox = b,
            xlabel = labels[i],
            aspect = 1,
            width = Relative(1),
            height = Relative(1),
            #halign = -15.5,
            #valign = 1.1,
            backgroundcolor = :white,
        ) =#

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

function calculate_BBox(origin, widths, predictor_value, bounds)

    minwidth = minimum(widths)
    predictor_ratio = (predictor_value - bounds[1]) / (bounds[2] - bounds[1])
    radius = (minwidth * 0.7) / 2
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
    return BBox(
        (origin[1] + widths[1]) / 2 - size_of_BBox / 2 + x,
        (origin[1] + widths[1]) / 2 + size_of_BBox - size_of_BBox / 2 + x,
        (origin[2] + widths[2]) / 2 - size_of_BBox / 2 + y,
        (origin[2] + widths[2]) / 2 + size_of_BBox - size_of_BBox / 2 + y,
    )
end

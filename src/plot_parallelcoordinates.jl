
"""
    plot_parallelcoordinates(f::Union{GridPosition, GridLayout, Figure}, data::DataFrame; kwargs)

Plot a PCP (parallel coordinates plot).

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`: Figure or GridPosition in which the plot should be drawn.
- `data::DataFrame`: data for the plot visualization.

## key word argumets (kwargs)

- `normalize` (default: `nothing`) - if `:minmax`, normalize each axis to their respective min-max range.
- `ax_labels` (Array, default: `nothing`) - specify axis names. 
    Should be a vector of labels with length equal to the number of unique `mapping.x` values.
    Example: `ax_labels` = ["Fz", "Cz", "O1", "O2"].
- `ax_ticklabels` (default `:outmost`) - specify tick labels on axis.
    - `:all` - show all labels on all axes.
    - `:left` - show all labels on the left axis, but only min and max on others. 
    - `:outmost` - show labels on min and max of all other axes. 
    - `:none` - remove all labels. 
- `bend` (default `false`) - change straight lines between the axes to curved ("bent") lines using spline interpolation.

## Defining the axes

- Default: `...(...; mapping=(; x=:channel, y=:estimate))` - one could overwrite what should be on the x and the y axes.
- By setting `...(...; mapping=(; color=:colorcolumn))` one defines conditions splitted by color. 
    The default color is defined by `...(...; visual=(; color=:black))`.

## Change transparency
use `...(...; visual=(; alpha=0.5))` to change transparency.


$(_docstring(:paracoord))

## Return Value:
The input `f`
"""
plot_parallelcoordinates(data::DataFrame; kwargs...) =
    plot_parallelcoordinates(Figure(), data; kwargs...)

function plot_parallelcoordinates(
    f,
    data::DataFrame;
    ax_ticklabels = :outmost,
    ax_labels = nothing,
    normalize = nothing,
    bend = false,
    kwargs...,
)
    config = PlotConfig(:paracoord)
    UnfoldMakie.config_kwargs!(config; kwargs...)

    config.mapping = UnfoldMakie.resolveMappings(data, config.mapping)


    # remove all unspecified columns
    d = select(data, config.mapping...)

    # stack the data to a matrix-like (still list of list of lists!)
    d2 = unstack(
        d,
        Not(config.mapping.x, config.mapping.y),
        config.mapping.x,
        config.mapping.y,
        combine = copy,
    )

    # remove the non x/y columns, we want a matrix at the end
    rm_col =
        filter(x -> x != config.mapping.x && x != config.mapping.y, [config.mapping...])
    d3 = select(d2, Not(rm_col))

    # give use list of matrix
    d4 = reduce.(hcat, eachrow(Array(d3)))

    # give us a single matrix
    d5 = reduce(vcat, d4)'

    # figure out the color vector
    if :color ∈ keys(config.mapping)
        c_split = map((c, n) -> repeat([c], n), d2[:, config.mapping.color], size.(d4, 1))
        c = vcat(c_split...)
        line_labels = string.(c)
    else
        c = config.visual.color
        line_labels = nothing
        if config.layout.show_legend
            @warn "Deactivating legend, as there was no color-choice"
            UnfoldMakie.config_kwargs!(config; layout = (; show_legend = false))
        end
    end
    UnfoldMakie.config_kwargs!(config; visual = (; color = c))

    f, ax, axlist, hlines = parallelcoordinates(
        f,
        d5;
        normalize = normalize,
        color = c,
        bend = bend,
        line_labels = line_labels,
        ax_labels = ax_labels,
        ax_ticklabels = ax_ticklabels,
        config.visual...,
    )
    applyLayoutSettings!(config; fig = f, ax = ax)

    return isa(f, Figure) ? Makie.FigureAxisPlot(f, [ax, axlist], hlines[1]) :
           Makie.AxisPlot([ax, axlist], hlines[1])
end


function parallelcoordinates(
    f::Union{<:Figure,<:GridPosition,<:GridLayout},
    data::AbstractMatrix;
    color = nothing,
    line_labels = nothing,
    colormap = Makie.wong_colors(),
    ax_labels = nothing,
    ax_ticklabels = :outmost, # :all, :left,:none
    normalize = :minmax,
    alpha = 0.3,
    bend = false,
)
    @assert size(data, 2) > 1 "currently more than one line has to be plotted for parallelplot to work"
    if isa(color, AbstractVector)
        @assert size(data, 2) == length(color)
    end
    x_pos = 1:size(data, 1)
    ax = Axis(f[1, 1])
    scene = ax.parent.scene

    ax_labels = isnothing(ax_labels) ? string.(1:size(data, 1)) : ax_labels

    # normalize the data?
    minlist = minimum.(eachrow((data)))
    maxlist = maximum.(eachrow((data)))
    if normalize == :minmax
        function norm_minmax(x, min, max)

            return (x .- min) ./ (max - min)
        end
        plotdata = deepcopy(data)
        for (mi, ma, r) in zip(minlist, maxlist, eachrow(plotdata))
            r .= norm_minmax(r, mi, ma)
        end
    else
        plotdata = data
        minlist = minimum(plotdata)
        maxlist = maximum(plotdata)
    end
    #    @debug plotdata
    # edge bending / bundling

    if !bend
        x_plotdata = x_pos
        plotdata_int = plotdata
    else
        x_plotdata = range(1, x_pos[end], step = 0.05)
        plotdata_int = Array{Float64}(undef, length(x_plotdata), size(plotdata, 2))
        for k = 1:size(plotdata, 2)
            itp = interpolate(plotdata[:, k], BSpline(Cubic(Interpolations.Line(OnGrid()))))
            plotdata_int[:, k] = itp.(x_plotdata)
        end
    end

    # color
    crange = [1, 2] # default
    if isnothing(color)
        color = 1
    elseif isa(color, AbstractVector)
        if isa(color[1], String)
            # categorical colors
            un_c = unique(color)
            color_ix = [findfirst(un_c .== c) for c in color]
            #@assert length(un_c) == 1 "Only single color found, please don't specify color, "
            if length(un_c) == 1
                @warn "only a single unique value found in specified color-vec"
                color = cgrad(colormap, 2)[color_ix]
            else
                color = cgrad(colormap, length(un_c))[color_ix]
            end
            #crange = [1,length(unique(color))]
        else
            # continuous color
            crange = [minimum(color), maximum(color)]
        end
    end

    # plot the lines - this way it will be easy to curve them too
    hlines = []
    for (ix, r) in enumerate(eachcol(plotdata_int))

        h = lines!(
            ax,
            x_plotdata,
            r;
            alpha = alpha,
            color = isa(color, AbstractVector) ? color[ix] : color,
            colormap = colormap,
            colorrange = crange,
            label = isa(line_labels, AbstractVector) ? line_labels[ix] : line_labels,
        )
        append!(hlines, [h])
    end

    # put the right limits + hide the data axes
    xlims!(ax, 1, size(data, 1))
    hidespines!(ax)
    hidedecorations!(ax)


    # get some defaults - necessary for LinkAxis
    def = Makie.default_attribute_values(Axis, nothing)
    axesOptions = (;
        spinecolor = :black,
        spinevisible = true,
        labelfont = def[:ylabelfont],
        labelrotation = def[:ylabelrotation],
        labelvisible = false,
        ticklabelfont = def[:yticklabelfont],
        ticklabelsize = def[:yticklabelsize],
        ticklabelalign = (:right, :center),
        minorticks = def[:yminorticks],
    )


    # generate the overlay parallel axes
    axlist = Makie.LineAxis[]
    for i in eachindex(x_pos)
        # link them to the parent axes size
        axis_endpoints = lift(ax.scene.px_area) do area
            center(x_pos[i], x_pos[end], area)
        end
        if isa(minlist, AbstractArray)
            limits = [minlist[i], maxlist[i]]
        else
            limits = [minlist, maxlist]
        end

        tickformater = Makie.automatic # default
        if ax_ticklabels == :outmost || (i != 1 && ax_ticklabels == :left)
            tickformater = surpress_inner_labels
        end
        if ax_ticklabels == :none
            tickformater = x -> repeat([""], length(x))
        end

        ax_pcp = Makie.LineAxis(
            scene;
            limits = limits,
            ticks = PCPTicks(),
            endpoints = axis_endpoints,
            tickformat = tickformater,
            axesOptions...,
        )
        pcp_title!(
            scene,
            ax_pcp.attributes.endpoints,
            ax_labels[i];
            titlegap = def[:titlegap],
        )



        append!(axlist, [ax_pcp])
    end


    # add some space to the left and top
    pro = ax.layoutobservables.protrusions[]
    ax.layoutobservables.protrusions[] = GridLayoutBase.RectSides(
        (axlist[1].protrusion[]),
        pro.right,
        pro.bottom,
        pro.top + def[:titlegap],
    )
    if normalize == :minmax
        ylims!(ax, 0, 1)
    else
        ylims!(ax, minimum(minlist), maximum(maxlist))
    end

    return f, ax, axlist, hlines
end

function surpress_inner_labels(val)
    lbl = Makie.Showoff.showoff(val)
    if length(lbl) > 2
        lbl[2:end-1] .= ""
    end
    return lbl
end

function center(x_pos, x_max, area)
    r = Rect2f(area)
    x = range(r.origin[1], r.origin[1] + r.widths[1], length = x_max)[x_pos]
    y = r.origin[2]
    Point2f[(x, y), (x, (y + r.widths[2]))]
end

function pcp_title!(
    topscene,
    endpoints::Observable,
    title::String;
    titlegap = Observable(4.0f0),
)
    titlepos = lift(endpoints, titlegap) do a, titlegap
        x = a[1][1]
        y = a[2][2] + titlegap
        Point2(x, y)
    end

    titlet = text!(
        topscene,
        title,
        position = titlepos,
        #visible = titlevisible,
        #textsize = titlesize,
        align = (:center, :bottom),
        #font = titlefont,
        #color = titlecolor,
        space = :data,
        #show_axis=false,
        inspectable = false,
    )
end


"""
Used to inject extrema ticks and round them if necessary
"""
struct PCPTicks end

function Makie.get_ticks(ticks::PCPTicks, scale, formatter, vmin, vmax)
    #@debug "get_ticks custom",vmin,vmax
    tickvalues = Makie.get_tickvalues(Makie.WilkinsonTicks(5), scale, vmin, vmax)

    ticklabels_without = Makie.get_ticklabels(formatter, tickvalues)
    if !(tickvalues[1] ≈ vmin)
        tickvalues = [vmin, tickvalues...]
    end
    if !(tickvalues[end] ≈ vmax)
        tickvalues = [tickvalues..., vmax]
    end

    ticklabels = Makie.get_ticklabels(formatter, tickvalues)
    maxlen = length(ticklabels_without[1])
    if length(ticklabels[1]) != maxlen
        ticklabels = first.(ticklabels, maxlen)
        ticklabels[1] = "~" * ticklabels[1]
        ticklabels[end] = "~" * ticklabels[end]
    end
    #@debug tickvalues,ticklabels
    return tickvalues, ticklabels
end

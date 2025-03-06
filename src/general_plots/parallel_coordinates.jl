

function parallel_coordinates(
    f::Union{<:Figure,<:GridPosition,<:GridLayout},
    outer_axis,
    data::AbstractMatrix;
    normalize = :minmax,
    color = nothing,
    bend = false,
    line_labels = nothing,
    colormap = Makie.wong_colors(),
    ax_labels = nothing,
    ax_ticklabels = :outmost, # :all, :left,:none
    alpha = 0.3,
)
    @assert size(data, 2) > 1 "Currently, parallel plotting requires plotting more than one line."
    if isa(color, AbstractVector)
        @assert size(data, 2) == length(color)
    end
    x_pos = 1:size(data, 1)

    scene = outer_axis.parent.scene

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

    # edge bending / bundling
    if !bend
        x_plotdata = x_pos
        plotdata_int = plotdata
    else
        x_plotdata = range(1, x_pos[end], step = 0.05)
        plotdata_int = Array{Float64}(undef, length(x_plotdata), size(plotdata, 2))
        for k = 1:size(plotdata, 2)
            itp = Interpolations.interpolate(
                plotdata[:, k],
                BSpline(Cubic(Interpolations.Line(OnGrid()))),
            )
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
            if length(un_c) == 1
                @warn "Only single unique value found in the specified color vector."
                color = cgrad(colormap, 2)[color_ix] # color gradient
            else
                color = cgrad(colormap, length(un_c))[color_ix]
            end
        else
            # continuous color
            crange = [minimum(color), maximum(color)]
        end
    end

    # plot the lines - this way it will be easy to curve them too
    hlines = []
    for (ix, r) in enumerate(eachcol(plotdata_int))
        h = lines!(
            outer_axis,
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
    xlims!(outer_axis, 1, size(data, 1))
    hidespines!(outer_axis)
    hidedecorations!(outer_axis, label = false)

    # get some defaults - necessary for LinkAxis
    def = Makie.default_attribute_values(Axis, nothing)
    axes_options = (;
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
        axis_endpoints = lift(outer_axis.scene.viewport) do area
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
            dim_convert = Makie.NoDimConversion(),
            ticks = PCPTicks(),
            endpoints = axis_endpoints,
            tickformat = tickformater,
            axes_options...,
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
    pro = outer_axis.layoutobservables.protrusions[]
    outer_axis.layoutobservables.protrusions[] = GridLayoutBase.RectSides(
        (axlist[1].protrusion[]),
        pro.right,
        pro.bottom,
        pro.top + def[:titlegap],
    )
    if normalize == :minmax
        ylims!(outer_axis, 0, 1)
    else
        ylims!(outer_axis, minimum(minlist), maximum(maxlist))
    end

    return f, outer_axis, axlist, hlines
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
        #fontsize = config.axis.titlefontsize,
        align = (:center, :bottom),
        #font = titlefont,
        #color = titlecolor,
        space = :data,
        #show_axis=false,
        inspectable = false,
    )
end

"""
    PCPTicks
Used to inject extrema ticks and round them if necessary.
"""
struct PCPTicks end

function Makie.get_ticks(ticks::PCPTicks, scale, formatter, vmin, vmax)
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
    return tickvalues, ticklabels
end

"""
    plot_erpgrid(data::Union{Matrix{<:Real}, DataFrame}, pos::Vector; kwargs...)
    plot_erpgrid!(f::Union{GridPosition, GridLayout, Figure}, data::Union{Matrix{<:Real}, DataFrame}, pos::Vector; kwargs...)

Plot an ERP image.
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{Matrix{<:Real}, DataFrame}`\\
    Data for the plot visualization.\\
    Data should has a format of 1 row - 1 channel. 
- `pos::Vector{Point{2,Float}}` \\
    Electrode positions.
        
## Keyword argumets (kwargs)
- `drawlabels::Bool = false`\\
    Draw channels labels over each waveform. 
- `times::Vector = 1:size(data, 2)`\\
    Vector of `size()`.

$(_docstring(:erpgrid))

**Return Value:** `Figure` displaying ERP grid.
"""
plot_erpgrid(data::Union{Matrix{<:Real},DataFrame}, pos; kwargs...) =
    plot_erpgrid!(Figure(), data, pos; kwargs...)

function plot_erpgrid!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Union{Matrix{<:Real},DataFrame},
    pos::Vector;
    drawlabels = false,
    times = -1:size(data, 2)-2, #arbitrary strat just for fun
    kwargs...,
)
    config = PlotConfig(:erpgrid)
    config_kwargs!(config; kwargs...)

    if typeof(data) == DataFrame #maybe better would be put it into signature
        data = Matrix(data)
    end

    chan_num = size(data, 1)
    data = data[1:chan_num, :]
    pos = hcat([[p[1], p[2]] for p in pos]...)

    pos = pos[:, 1:chan_num]
    minmaxrange = (maximum(pos, dims = 2) - minimum(pos, dims = 2))
    pos = (pos .- mean(pos, dims = 2)) ./ minmaxrange .+ 0.5

    axlist = []
    rel_zeropoint = argmin(abs.(times)) ./ length(times)

    for (ix, p) in enumerate(eachcol(pos))
        x = p[1] #- 0.1 #some padding needed
        y = p[2] #- 0.1
        # todo: 0.1 should go into plot config
        ax = Axis(
            f[1, 1],
            width = Relative(0.2),
            height = Relative(0.2),
            halign = x,
            valign = y,
        )# title = raw_ch_names[1:30])
        if drawlabels
            text!(
                ax,
                rel_zeropoint + 0.1,
                1,
                color = :gray,
                fontsize = 12,
                text = string.(ix),
                align = (:left, :top),
                space = :relative,
            )
        end
        # todo: add label if not nothing

        push!(axlist, ax)
    end
    # todo: make optional + be able to specify the linewidth + color
    hlines!.(axlist, Ref([0.0]), color = :gray, linewidth = 0.5)
    vlines!.(axlist, Ref([0.0]), color = :gray, linewidth = 0.5)

    times = isnothing(times) ? (1:size(data, 2)) : times

    # todo: add customizable kwargs
    h = lines!.(axlist, Ref(times), eachrow(data))

    linkaxes!(axlist...)
    hidedecorations!.(axlist)
    hidespines!.(axlist)

    ax2 = Axis(f[1, 1], width = Relative(1.05), height = Relative(1.05))
    hidespines!(ax2)
    hidedecorations!(ax2, label = false)
    xlims!(ax2, config.axis.xlim)
    ylims!(ax2, config.axis.ylim)
    xstart = [Point2f(0), Point2f(0)]
    xdir = [Vec2f(0, 0.1), Vec2f(0.1, 0)]
    arrows!(xstart, xdir, arrowsize = 10)
    text!(0.02, 0, text = config.axis.xlabel, align = (:left, :top), fontsize = 12)
    text!(
        -0.008,
        0.01,
        text = config.axis.ylabel,
        align = (:left, :baseline),
        rotation = π / 2,
        fontsize = 12,
    )
    # testing
    #ax0 = Axis(f[1, 1], backgroundcolor=:green)#
    #hidespines!(ax0)
    #hidedecorations!(ax0)
    f
end

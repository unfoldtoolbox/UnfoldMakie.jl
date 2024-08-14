"""
    plot_erpgrid(data::Union{Matrix{<:Real}, DataFrame}, positions::Vector; kwargs...)
    plot_erpgrid!(f::Union{GridPosition, GridLayout, Figure}, data::Union{Matrix{<:Real}, DataFrame}, positions::Vector, ch_names::Vector{String}; kwargs...)

Plot an ERP image.
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{Matrix{<:Real}, DataFrame}`\\
    Data for the plot visualization.\\
    Data should has a format of 1 row - 1 channel. 
- `positions::Vector{Point{2,Float}}` \\
    Electrode positions.
- `ch_names::Vector{String}`\\
    Vector with channel names.
        
## Keyword arguments (kwargs)
- `drawlabels::Bool = false`\\
    Draw channels labels over each waveform. 
- `times::Vector = 1:size(data, 2)`\\
    Vector of `size()`.

$(_docstring(:erpgrid))

**Return Value:** `Figure` displaying ERP grid.
"""
plot_erpgrid(
    data::Union{Matrix{<:Real},DataFrame},
    positions::Vector,
    ch_names::Vector{String};
    kwargs...,
) = plot_erpgrid!(Figure(), data, positions, ch_names; kwargs...)

plot_erpgrid!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Union{Matrix{<:Real},DataFrame},
    positions;
    kwargs...,
) = plot_erpgrid!(f, data, positions, string.(1:length(positions)); kwargs...)

plot_erpgrid(data::Union{Matrix{<:Real},DataFrame}, positions; kwargs...) =
    plot_erpgrid!(Figure(), data, positions, string.(1:length(positions)); kwargs...)

function plot_erpgrid!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Union{Matrix{<:Real},DataFrame},
    positions::Vector,
    ch_names::Vector{String};
    drawlabels = false,
    times = -1:size(data, 2)-2, #arbitrary
    kwargs...,
)
    config = PlotConfig(:erpgrid)
    config_kwargs!(config; kwargs...)

    if typeof(data) == DataFrame #maybe better would be put it into signature?
        data = Matrix(data)
    end
    if length(positions) != length(ch_names)
        error(
            "Length of positions and channel names are not equal: $(length(positions)) and $(length(ch_names))",
        )
    end
    if size(data, 1) != length(positions)
        error(
            "Number of data rows and positions length are not equal: $(size(data, 1)) and $(length(positions))",
        )
    end
    positions = hcat([[p[1], p[2]] for p in positions]...)
    minmaxrange = (maximum(positions, dims = 2) - minimum(positions, dims = 2)) #should be different for x and y
    positions = (positions .- mean(positions, dims = 2)) ./ minmaxrange .+ 0.5

    axlist = []
    rel_zeropoint = argmin(abs.(times)) ./ length(times)
    for (ix, p) in enumerate(eachcol(positions))
        x = p[1]
        y = p[2]
        ax = Axis(
            f[1, 1],
            width = Relative(0.2),
            height = Relative(0.2),
            halign = x,
            valign = y,
        )
        if drawlabels
            text!(
                ax,
                rel_zeropoint + 0.1,
                1,
                color = :gray,
                fontsize = 12,
                text = ch_names[ix],
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
    f
end

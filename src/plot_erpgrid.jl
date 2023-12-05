"""
    plot_erpgrid!(f::Union{GridPosition, GridLayout, Figure}, data::Matrix{<:Real}, pos::Vector{Point{2,Float}}; kwargs...)
    plot_erpgrid(data::Matrix{<:Real}, pos::Vector{Point{2,Float}}; kwargs...)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`: Figure, GridLayout or GridPosition that the plot should be drawn into.
- `data::Matrix{<:Real}`: data for the plot visualization.
- `pos::Vector{Point{2,Float}}`: electrode positions.
        
## Keyword Arguments
- `drawlabels` (bool, `false`): draw channels labels over each waveform. 
- `times`: (Vector, `1:size(data, 2)`): vector of size()

$(_docstring(:erpgrid))

## Return Value:
The figure displaying ERP grid
"""
plot_erpgrid(data::Matrix{<:Real}, pos; kwargs...) =
    plot_erpgrid!(Figure(), data, pos; kwargs...)

function plot_erpgrid!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Matrix{<:Real},
    pos;
    drawlabels = false,
    times = -1:size(data, 2)-2, #arbitrary strat just for fun
    kwargs...,
)
    config = PlotConfig(:erpgrid)
    config_kwargs!(config; kwargs...)

    chanNum = size(data, 1)
    data = data[1:chanNum, :]
    pos = hcat([[p[1], p[2]] for p in pos]...)

    pos = pos[:, 1:chanNum]
    minmaxrange = (maximum(pos, dims = 2) - minimum(pos, dims = 2))
    pos = (pos .- mean(pos, dims = 2)) ./ minmaxrange .+ 0.5

    axlist = []
    #ax = Axis(f[1, 1],backgroundcolor=:green)#

    rel_zeropoint = argmin(abs.(times)) ./ length(times)

    for (ix, p) in enumerate(eachcol(pos))
        x = p[1] #- 0.1
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

    f

end

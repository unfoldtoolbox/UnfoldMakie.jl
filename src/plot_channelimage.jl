"""
    plot_channelimage!(f::Union{GridPosition, GridLayout, Figure}, data::Matrix{<:Real}, position::Vector{Point{2,Float32}}, ch_names::Vector{String}; kwargs...)
    plot_channelimage(data::Matrix{<:Real}, position::Vector{Point{2,Float32}}, ch_names::Vector{String}; kwargs...)
        
Channel image

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`
    - `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::DataFrame`
    - DataFrame with data.
- `position::Vector{Point{2,Float32}}`
    - A vector with EEG layout coordinates.
- `ch_names::Vector{String}`
    - Vector with channel names.

$(_docstring(:channelimage))

**Return Value:** `Figure` displaying the Channel image.

"""
plot_channelimage(
    data::Matrix{<:Real},
    position::Vector{Point{2,Float32}},
    ch_names::Vector{String};
    kwargs...,
) = plot_channelimage!(Figure(), data, position, ch_names; kwargs...)

function plot_channelimage!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Matrix{<:Real},
    position::Vector{Point{2,Float32}},
    ch_names::Vector{String};
    kwargs...,
)
    config = PlotConfig(:channelimage)
    config_kwargs!(config; kwargs...)

    x = [i[1] for i in position]
    y = [i[2] for i in position]

    x = round.(x; digits = 2)
    y = Integer.(round.((y .- mean(y)) * 20)) * -1
    x = Integer.(round.((x .- mean(x)) * 20))
    d = zip(x, y, ch_names, 1:20)
    a = sort!(DataFrame(d), [:2, :1], rev = [true, false])
    b = a[!, :4]
    c = a[!, :3]
    c = [string(x) for x in c]

    ix = range(-0.3, 1.2, length = size(data, 2))
    iy = 1:20
    iz = mean(data, dims = 3)[b, :, 1]'

    gin = f[1, 1] = GridLayout()
    ax = Axis(gin[1, 1], xlabel = config.axis.xlabel, ylabel = config.axis.ylabel)
    hm = Makie.heatmap!(ix, iy, iz, colormap = config.visual.colormap)
    ax.yticks = iy
    ax.ytickformat = xc -> c
    ax.yticklabelsize = config.axis.yticklabelsize

    Makie.Colorbar(
        gin[1, 2],
        hm,
        label = config.colorbar.label,
        labelrotation = config.colorbar.labelrotation,
    )
    return f
end

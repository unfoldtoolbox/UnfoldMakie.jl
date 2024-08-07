"""
    plot_channelimage!(f::Union{GridPosition, GridLayout, Figure}, data::Matrix{<:Real}, position::Vector{Point{2,Float32}}, ch_names::Vector{String}; kwargs...)
    plot_channelimage(data::Matrix{<:Real}, position::Vector{Point{2,Float32}}, ch_names::Vector{String}; kwargs...)
        
Plot a Channel image

## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::DataFrame`\\
    DataFrame with data.
- `position::Vector{Point{2,Float32}}`\\
    A vector with EEG layout coordinates.
- `ch_names::Vector{String}`\\
    Vector with channel names.
- `times::?`\\
    Time range on x-axis.

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
    times = range(-0.3, 1.2, length = size(data, 2)),
    kwargs...,
)
    config = PlotConfig(:channelimage)
    config_kwargs!(config; kwargs...)
    if length(position) != length(ch_names)
        error(
            "Length of positions and channel names are not equal: $(length(position)) and $(length(ch_names))",
        )
    end

    x = [i[1] for i in position]
    y = [i[2] for i in position]

    x = round.(x; digits = 2)
    y = Integer.(round.((y .- mean(y)) * length(y))) * -1
    x = Integer.(round.((x .- mean(x)) * length(y)))
    d = DataFrame(zip(x, y, ch_names, 1:length(ch_names)))

    a = sort!(d, [:2, :1], rev = [true, false])
    b = a[!, :4]
    c = a[!, :3]
    c = [string(x) for x in c]

    iy = 1:length(ch_names)
    iz = mean(data, dims = 3)[b, :, 1]'

    gin = f[1, 1] = GridLayout()
    ax = Axis(gin[1, 1], xlabel = config.axis.xlabel, ylabel = config.axis.ylabel)
    hm = Makie.heatmap!(times, iy, iz, colormap = config.visual.colormap)
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

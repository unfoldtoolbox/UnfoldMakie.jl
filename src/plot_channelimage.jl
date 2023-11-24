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
    ax = Axis(gin[1, 1], xlabel = "Time [s]", ylabel = "Channels")
    hm = Makie.heatmap!(ix, iy, iz, colormap = "cork")
    ax.yticks = iy
    ax.ytickformat = xc -> c
    ax.yticklabelsize = 14

    Makie.Colorbar(gin[1, 2], hm, label = "Voltage [µV]")
    return f
end

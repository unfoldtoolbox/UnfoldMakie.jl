"""
    plot_channelimage!(f::Union{GridPosition, GridLayout, Figure}, data::Union{DataFrame,AbstractMatrix}, positions::Vector{Point{2,Float32}}, ch_names::Vector{String}; kwargs...)
    plot_channelimage(data::Union{DataFrame, AbstractMatrix}, positions::Vector{Point{2,Float32}}, ch_names::Vector{String}; kwargs...)
        
Plot a Channel image

## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, AbstractMatrix}`\\
    DataFrame or Matrix with data.\\
    Data should has a format of 1 row - 1 channel. 
- `positions::Vector{Point{2,Float32}}`\\
    A vector with EEG layout coordinates.
- `ch_names::Vector{String}`\\
    Vector with channel names.
- `times::Vector = range(-0.3, 1.2, length = size(data, 2))`\\
    Time range on x-axis.
- `sorting_variables::Vector = [:y, :x]`\\
    Method to sort channels on y-axis.\\
    For instance, you can sort by channel positions on the scalp (x, y) or channel name. 
- `sorting_reverse::Vector = [:false, :false]`\\
   Should sorting variables be reversed or not?

$(_docstring(:channelimage))

**Return Value:** `Figure` displaying the Channel image.

"""
plot_channelimage(
    data::Union{DataFrame,AbstractMatrix},
    position::Vector{Point{2,Float32}},
    ch_names::Vector{String};
    kwargs...,
) = plot_channelimage!(Figure(), data, position, ch_names; kwargs...)

function plot_channelimage!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Union{DataFrame,AbstractMatrix},
    positions::Vector{Point{2,Float32}},
    ch_names::Vector{String};
    times = range(-0.3, 1.2, length = size(data, 2)),
    sorting_variables = [:y, :x],
    sorting_reverse = [:false, :false],
    kwargs...,
)
    config = PlotConfig(:channelimage)
    config_kwargs!(config; kwargs...)
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
    if length(sorting_variables) != length(sorting_reverse)
        error(
            "Length of sorting_variables and sorting_reverse are not equal: $(length(sorting_variables)) and $(length(sorting_reverse))",
        )
    end

    x = [i[1] for i in positions]
    y = [i[2] for i in positions]

    sorted_data =
        DataFrame(:x => x, :y => y, :ch_names => ch_names, :index => 1:length(ch_names))

    sort!(sorted_data, sorting_variables, rev = sorting_reverse)
    sorted_names = sorted_data[!, :ch_names]
    sorted_names = [string(x) for x in sorted_names]
    sorted_indecies = sorted_data[!, :index]

    if typeof(data) == DataFrame
        data = Matrix(data)
    end
    iz = mean(data, dims = 3)[sorted_indecies, :, 1]' 

    gl = f[1, 1] = GridLayout()
    ax = Axis(
        gl[1, 1],
        xlabel = config.axis.xlabel,
        xticks = round.(LinRange(minimum(times), maximum(times), 5), digits = 2),
        ylabel = config.axis.ylabel,
        yticks = 1:length(ch_names),
        ytickformat = xc -> sorted_names,
        yticklabelsize = config.axis.yticklabelsize,
    )

    cb_ticks = LinRange(minimum(iz), maximum(iz), 5)
    rounded_cb_ticks = string.(round.(cb_ticks, digits = 2))
    config_kwargs!(config, colorbar = (; ticks = (cb_ticks, rounded_cb_ticks)))
    hm = Makie.heatmap!(times, 1:length(ch_names), iz, colormap = config.visual.colormap)
    Colorbar(gl[1, 2], hm; config.colorbar...)
    return f
end

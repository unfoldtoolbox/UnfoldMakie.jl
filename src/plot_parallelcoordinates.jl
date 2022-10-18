using LinearAlgebra
#using Pipe
#using PyMNE




"""
    function plot_parallelcoordinates!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig; channels::Vector{Int64})

Plot a PCP (parallel coordinates plot).
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: Data for the plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
- `channels::Vector{Int64}`: vector with all the channels representing an axis used in the PCP in given order.

## Extra Data Behavior:

PCP has problems with size changes of the view window.
By adapting the padding, aspect ratio and tick label size in px for a new use case, the PCP can even be added into a Coordinated Multiple Views System

`pc_aspect_ratio`  Default : `0.55`

`pc_right_padding`  Default : `15`

`pc_left_padding`  Default : `25`

`pc_top_padding`  Default : `26`

`pc_bottom_padding`  Default : `16`

`pc_tick_label_size`  Default : `14`

## Return Value:
The input `f`
"""
plot_parallelcoordinates(plotData::DataFrame, config::PlotConfig,channels;kwargs...) = plot_parallelcoordinates!(Figure(), plotData, config,channels;kwargs...)
plot_parallelcoordinates(plotData::DataFrame,channels::Vector{Int64};kwargs...) = plot_parallelcoordinates(plotData, PlotConfig(:paracoord),channels;kwargs...)
plot_parallelcoordinates!(f::Union{GridPosition, Figure},plotData::DataFrame,channels;kwargs...) = plot_parallelcoordinates!(f,plotData, PlotConfig(:paracoord),channels;kwargs...)

function plot_parallelcoordinates!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig, channels::Vector{Int64};kwargs...)
    @show kwargs
    config_kwargs!(config;kwargs...)
    # We didn't find a good formula to set these automatically
    # have to be set manually for now
    # if size of the plot-area changes the padding gets weird
    aspect_ratio = config.extraData.pc_aspect_ratio
    right_padding = config.extraData.pc_right_padding
    left_padding = config.extraData.pc_left_padding
    top_padding = config.extraData.pc_top_padding
    bottom_padding = config.extraData.pc_bottom_padding
    tick_label_size = config.extraData.pc_tick_label_size
    
    # have to be set now to reduce weird behaviour
    width = 500
    height = aspect_ratio * width
    ch_label_offset = 15
    
    # axis for plot
    ax = Axis(f[1, 1]; config.axisData...)
    
    # colormap border (prevents from using outer parts of color map)
    bord = 0
    
    config.mappingData = resolveMappings(plotData,config.mappingData)
    
    categories = unique(plotData[:,config.mappingData.category])
    catLeng = length(categories)
    chaLeng = length(channels)
    
    # x position of the axes
    x_values = Array(left_padding:(width-left_padding)/(chaLeng-1):width)
    # height of the upper labels
    y_values = fill(height, chaLeng)

    colormap = cgrad(config.visualData.colormap, (catLeng < 2) ? 2 + (bord*2) : catLeng + (bord*2), categorical = true)
    colors = Dict{String,RGBA{Float64}}()

    # get a colormap for each category
    for i in eachindex(categories)
        setindex!(colors, colormap[i+bord], categories[i])
    end

    n = length(channels) # number of axis
    k = 20

    # axes

    limits = [] ; l_low = [] ; l_up = []
    
    # get extrema for each channel
    for cha in channels
        tmp = filter(x -> (x[config.mappingData.channel] == cha),  plotData) 
        w = extrema.([tmp[:,config.mappingData.y]])
        append!(limits, w)
        append!(l_up, w[1][2])
        append!(l_low, w[1][1])

    end
    
    # Draw vertical line for each channel
    for i in 1:n
        x = (i - 1) / (n - 1) * width
        if i == 1
            switch = true
        else
            switch = false
        end
        Makie.LineAxis(ax.scene, 
            limits = limits[i],
            spinecolor = :black,
            labelfont = "Arial", 
            ticklabelfont = "Arial",
            spinevisible = true, 
            ticklabelsize = tick_label_size,
            minorticks = IntervalsBetween(2), 
            endpoints = Point2f[(x_values[i], bottom_padding), (x_values[i], y_values[i])],
            ticklabelalign = (:right, :center),
            labelvisible = false)
    end
    
    # Draw colored line through all channels for each time entry 
    for time in unique(plotData[:,config.mappingData.time]) 
        tmp1 = filter(x -> (x[config.mappingData.time] == time),  plotData) #1 timepoint, 10 rows (2 conditions, 5 channels)
        for cat in categories
            # df with the order of the channels
            dfInOrder = plotData[[],:]
            tmp2 = filter(x -> (x[config.mappingData.category] == cat),  tmp1)
            
            # create new dataframe with the right order
            for cha in channels
                append!(dfInOrder,filter(x -> (x[config.mappingData.channel] == cha),  tmp2))
            end
            
            values = map(1:n, dfInOrder[:,config.mappingData.y], limits) do q, d, l # axes, data, limis
                x = (q - 1) / (n - 1) * width
                Point2f(x_values[q], (d - l[1]) ./ (l[2] - l[1]) * (y_values[q]-bottom_padding) + bottom_padding)
                end
            lines!(ax.scene, values; color = colors[cat], config.visualData...)
        end
    end 
    
    channelNames = channelToLabel(channels) 

    # helper, because without them they wouldn#t have an entry in legend
    for cat in categories
        lines!(ax, 1, 1, 1, label = cat, color = colors[cat])
    end
    
    # labels
    text!(x_values, y_values, text = channelNames, align = (:center, :center), 
        offset = (0, ch_label_offset * 2), 
        color = :blue)
    # lower limit text
    text!(x_values, fill(0, chaLeng), align = (:right, :bottom),  text = string.(round.(l_low, digits=1)))
    # upper limit text
    text!(x_values, y_values, align = (:right, :bottom), text = string.(round.(l_up, digits=1)))
    Makie.xlims!(low = 0, high = width + right_padding)
    Makie.ylims!(low = 0, high = height + top_padding)

    applyLayoutSettings(config; fig = f, ax=ax)

    # ensures the axis numbers aren't squished
    ax.aspect = DataAspect()
    return f 
end
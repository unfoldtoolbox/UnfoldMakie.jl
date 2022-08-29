using LinearAlgebra
using Pipe
using PyMNE

"""
    function plot_paraCoord(plotData::DataFrame, config::PlotConfig; channels::Vector{Int64}=[])

Plot a PCP (parallel coordinates plot).
## Arguments:
- `plotData::DataFrame`: data for the PCP being visualized.
- `config::PlotConfig`: data of the configuration being applied to the visualization.
- `channels::Vector{Int64}=[]`: vector for all axes used in the PCP.

## Behavior: TODO?
### `config.extraData.-`:

## Return Value:
The figure displaying the PCP.
"""
function plot_paraCoord(plotData::DataFrame, config::PlotConfig; channels::Vector{Int64})
    plot_paraCoord!(Figure(), plotData, config; channels)
end

function plot_paraCoord!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig; channels::Vector{Int64})
    aspectRatio = 1
    
    width = 900
    height = aspectRatio * width
    
    # axis_bottom_offset = 50
    # ch_label_offset = 14
    # right_padding = 50
    # upper_padding = 100
    # left_padding = 50
    
    
    axis_bottom_offset = max(height * 0.06,20)
    ch_label_offset = 14
    right_padding = max(width * 0.1, 60)
    upper_padding = min(height * 0.7, 50)
    left_padding = width * 0.1
    
    @show right_padding
    @show left_padding
    @show upper_padding
    @show axis_bottom_offset

    ax = Axis(f[1, 1])
    
    # colormap border (prevents from using outer parts of color map)
    bord = 1
    
    config.resolveMappings(plotData)
    
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
        w = extrema.([tmp[:,config.mappingData.yhat]])
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
        Makie.LineAxis(ax.scene,  limits = limits[i], # maybe consider as unique axis????
            spinecolor = :black, labelfont = "Arial", 
            ticklabelfont = "Arial", spinevisible = true,  ticklabelsvisible = switch, 
            minorticks = IntervalsBetween(2),  tickcolor = :red, 
            endpoints = Point2f[(x_values[i], axis_bottom_offset), (x_values[i], y_values[i])],
            ticklabelalign = (:right, :center), labelvisible = false)
    end
    # @show limits
    
    
    
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
            
            values = map(1:n, dfInOrder[:,config.mappingData.yhat], limits) do q, d, l # axes, data, limis
                x = (q - 1) / (n - 1) * width
                Point2f(x_values[q], (d - l[1]) ./ (l[2] - l[1]) * (y_values[q]-axis_bottom_offset) + axis_bottom_offset)
                end
            lines!(ax.scene, values; color = colors[cat], config.visualData...)
        end
    end 

    
    channelNames = channelToLabel(channels) 

    
    # helper, cuz without them they wouldn#t have an entry in legend
    for cat in categories
        lines!(ax, 1, 1, 1, label = "jhdfsghksdfjkhsdfjkghdfs", color = colors[cat])
    end
    
    applyLayoutSettings(config; fig = f)

    # labels
    text!(x_values, y_values, text = channelNames, align = (:center, :center), 
        offset = (0, ch_label_offset * 2), 
        color = :blue)
    # lower limit text
    text!(x_values, fill(0, chaLeng), align = (:center, :bottom),  text = string.(round.(l_low, digits=1)))
    # upper limit text
    text!(x_values, y_values, align = (:center, :bottom), text = string.(round.(l_up, digits=1)))
    #println(string.(round.(l_low, digits=2)))
    Makie.xlims!(low = 0, high = width + right_padding)
    Makie.ylims!(low = 0, high = height + upper_padding)

    hidespines!(ax) 
    hidedecorations!(ax, label = false)

    # ensures the axis numbers aren't squished
    ax.aspect = DataAspect()
    # ax.aspect = DataAspect()
    return f 
end
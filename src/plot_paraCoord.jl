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
    # colormap border (prevents from using outer parts of color map)
    bord = 0
    
    config.resolveMappings(plotData)
    
    premadeNames = ["FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7", "P9", "PO7", "PO3", "O1", "Oz", "Pz", "CPz", "FP2", "Fz", "F4", "F8", "FC4", "FCz", "Cz", "C4", "C6", "P4", "P8", "P10", "PO8", "PO4", "O2", "HEOG_left", "HEOG_right", "VEOG_lower"]
    
    categories = unique(plotData[:,config.mappingData.category])
    
    catLeng = length(categories)
    chaLeng = length(channels)
    

    colormap = cgrad(config.visualData.colormap, (catLeng < 2) ? 2 + (bord*2) : catLeng + (bord*2), categorical = true)
    colors = Dict{String,RGBA{Float64}}()

    # get a colormap for each category
    for i in eachindex(categories)
        setindex!(colors, colormap[i+bord], categories[i])
    end

    n = length(channels) # number of axis
    k = 20

    # axes
    width = 600;   height = 400 ;   offset = 90;   
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
        Makie.LineAxis(f.scene,  limits = limits[i], # maybe consider as unique axis????
            spinecolor = :black, labelfont = "Arial", 
            ticklabelfont = "Arial", spinevisible = true,  ticklabelsvisible = switch, 
            minorticks = IntervalsBetween(2),  tickcolor = :red, 
            endpoints = Point2f[(offset + x, offset), (offset + x, offset + height)],
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
                Point2f(offset + x, (d - l[1]) ./ (l[2] - l[1]) * height + offset)
                end
            lines!(f.scene, values; color = colors[cat], config.visualData...)
        end
    end 

    ax = f[1, 1] = Axis(f.scene)

    # helper, cuz without them they wouldn#t have an entry in legend
    for cat in categories
        lines!(ax, 1, 1, 1, label = cat, color = colors[cat])
    end

    hidespines!(ax) 
    hidedecorations!(ax, label = false) 

    applyLayoutSettings(config; fig = f, ax = ax)
    
    # the width of the plot is set, so the labels have to be placed evenly
    x = Array(10:(380-10)/(chaLeng-1):380)
    # height of plot
    y = fill(105, chaLeng)
    
    channelNames = premadeNames[channels] 
    
    ax = Axis(f[1, 1])
    


    text!(x, y, text = channelNames, align = (:center, :center), 
        offset = (0, 0), 
        color = :blue)
        
    text!(x, fill(5, chaLeng),  text = string.(round.(l_low, digits=1)))
    text!(x, fill(95, chaLeng),  text = string.(round.(l_up, digits=1)))
    #println(string.(round.(l_low, digits=2)))
    Makie.xlims!(low = -20, high = 440)
    Makie.ylims!(low = 0, high = 110)

    hidespines!(ax) 
    hidedecorations!(ax, label = false) 
   
    return f 
end
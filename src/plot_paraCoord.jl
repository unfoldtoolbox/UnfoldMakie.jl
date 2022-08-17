using LinearAlgebra
using Pipe
using PyMNE

function plot_paraCoord(dataFrame::DataFrame, config::PlotConfig, raw)
    
    channels = [10, 11, 14, 28, 29] #[2, 3, 17, 18, 19] 
    data = @pipe dataFrame |> 
        filter(x -> x.channel in channels, _) |>
        select(_, Not([:basisname, :condition])) 

    categories = unique(dataFrame.category)
    catLeng = length(categories)

    colormap = cgrad(config.visualData.colormap, (catLeng < 2) ? 2 : catLeng, categorical = true)
    colors = Dict{String,RGBA{Float64}}()
    @show colors
    # get a colormap for each category
    for i in eachindex(categories)
        @show i
        @show colormap[i]
        setindex!(colors, colormap[i], categories[i])
    end

    n = length(channels) # number of axis
    k = 20

    # axes
    f = Figure()
    width = 600;   height = 400 ;   offset = 90;   
    limits = [] ; l_low = [] ; l_up = []
    
    # get extrema for each channel
    for cha in channels
        tmp = filter(x -> (x.channel == cha),  data) 
        w = extrema.([tmp.yhat])
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

    # Draw colored line through all channels for each time entry
    for time in unique(data.time) 
        tmp1 = filter(x -> (x.time == time),  data) #1 timepoint, 10 rows (2 conditions, 5 channels) 
        for cat in categories
            tmp2 = filter(x -> (x.category == cat),  tmp1)
            values = map(1:n, tmp2.yhat, limits) do q, d, l # axes, data
                x = (q - 1) / (n - 1) * width
                Point2f(offset + x, (d - l[1]) ./ (l[2] - l[1]) * height + offset) 
                
                    end
            lines!(f.scene, values; color = colors[cat])
        end
    end 
    
    ax = f[1, 1] = Axis(f.scene)

    # helper, cuz without them they wouldn#t have an entry in legend
    for cat in categories
        lines!(ax, 1, 1, 1, label = cat, color = colors[cat])
    end
    axislegend(ax; config.legendData...)

    hidespines!(ax) 
    hidedecorations!(ax, label = false) 

    ax.xlabel = "Channels";    ax.ylabel = "Timestamps"
    x = Array(10:90:380)
    y = fill(105, 5)

    
    channelNames = raw.ch_names[channels] 

    ax = Axis(f[1, 1])
    text!(x, y, text = channelNames, align = (:center, :center), 
        offset = (0, 0), 
        color = :blue)
        
    text!(x, fill(5, 5),  text = string.(round.(l_low, digits=1)))
    text!(x, fill(95, 5),  text = string.(round.(l_up, digits=1)))
    #println(string.(round.(l_low, digits=2)))
    Makie.xlims!(low = -20, high = 440)
    Makie.ylims!(low = 0, high = 110)

    hidespines!(ax) 
    hidedecorations!(ax, label = false) 
   
    return f 
end
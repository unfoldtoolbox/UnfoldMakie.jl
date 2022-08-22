using DataFrames
using TopoPlots
using LinearAlgebra

"""
    plot_line(results::DataFrame, config::PlotConfig)

Plot a line plot.
## Arguments:
- `results::DataFrame`: data for the line plot being visualized.
- `config::PlotConfig`: data of the configuration being applied to the visualization.

## Behavior:
### `config.extraData.stderror`: 
Indicating whether the data estimates should be complemented 
with lower and higher estimates based on the stderror. 
Lower estimates is gained by pointwise subtraction of the stderror from the estimates. 
Higher estimates is gained by pointwise addition of the stderror to the estimates. 
Both estimates are then included in the mapping.
### `config.extraData.categoricalColor`:
Indicates whether it should be categorized based on color. 
Every line will get its discrete enty in the legend.
### `config.extraData.categoricalGroup`:
Indicates whether it should be categorized based on group.
The legend is a colorbar.
Should not be set in conjunction with `config.extraData.categoricalColor`.
### `config.extraData.topoLegend`:




## Return Value:

"""
function plot_line(results::DataFrame, config::PlotConfig)
    results = deepcopy(results)
    f = Figure()
    
    # @show names(results)
    # if isnothing(config.mappingData.y)
    #     config.mappingData.y = "estimate" ∈  names(results) ? :estimate : "yhat" ∈  names(results) ? :yhat : @error("please specify y-axis")
    # end
    if "group" ∈  names(results)
        results.group = results.group .|> a -> isnothing(a) ? :fixef : a
    end
    
    if "stderror" ∈  names(results) && config.extraData.stderror
        results.stderror = results.stderror .|> a -> isnothing(a) ? 0. : a
        results[!,:se_low]  = results[:,config.mappingData.y] .- results.stderror
        results[!,:se_high] = results[:,config.mappingData.y] .+ results.stderror
    end
    
    # Get topocolors if topoPlot Legend active
    if (config.extraData.topoLegend) 
        allPositions, colors = getTopoColor(results, config)
    end

    # return allPositions
    # Categorical mapping
    # convert color column into string, so no wrong grouping happens
    if config.extraData.categoricalColor && (:color ∈ keys(config.mappingData))
        # if color is used, use upper line
        # results[!, config.mappingData.color] = results[!, config.mappingData.color] .|> c -> string(c)
        config.mappingData = merge(config.mappingData,(;color=config.mappingData.color=>nonnumeric))
    end
    # converts group column into string
    if config.extraData.categoricalGroup && (:group ∈ keys(config.mappingData))
        # if color is used, use upper line
        # results[!, config.mappingData.group] = results[!, config.mappingData.group] .|> c -> string(c)
        config.mappingData = merge(config.mappingData,(;group=config.mappingData.group=>nonnumeric))
    end

    # pValues will break if x and y are included in this step
    mapp = mapping(;filterNamesOutTuple(config.mappingData, (:x, :y))...)
    
    xy_mapp = mapping(config.mappingData.x, config.mappingData.y)

    basic = visual(Lines) * xy_mapp
    if config.extraData.stderror
        m_se = mapping(config.mappingData.x,:se_low,:se_high)
        basic = basic + visual(Band,alpha=0.5)*m_se
    end
    
    basic = basic * data(results)

    # add the pvalues
    if !isempty(config.extraData.pvalue)
        basic =  basic + addPvalues(results, config)
    end
    
    plotEquation = basic * mapp
    # return plotEquation
    
    # add topoLegend if topoPlot Legend active
    if (config.extraData.topoLegend)    
        topoplotLegend(f, allPositions)
        drawing = draw!(f[1,1],plotEquation; palettes=(color=colors,))
    else
        drawing = draw!(f[1,1],plotEquation)
    end
    # if palettes=(color=colors,), nonnumeric columns crash program
    # drawing = draw!(f[1,1],plotEquation; colormap=:grays)
    
    applyLayoutSettings(config; fig = f, drawing = drawing)

    return f
    
end


function plot_results(results::DataFrame;y=nothing,
    color=:coefname,
    col=:basisname,
    row=:group,
    stderror=false,
    pvalue = DataFrame(:from=>[],:to=>[]),
    kwargs...)

    results = deepcopy(results)

    @assert "time" ∈ names(results) ":time has to be a column of the input dataframe"

    if isnothing(y)
        y = "estimate" ∈  names(results) ? :estimate : "yhat" ∈  names(results) ? :yhat : @error("please specify y-axis")
    end
    
    # replace missing/nothing values
    if "group" ∈  names(results)
        results.group = results.group .|> a -> isnothing(a) ? :fixef : a
    end
    if "stderror" ∈  names(results) && stderror
        results.stderror = results.stderror .|> a -> isnothing(a) ? 0. : a
        results[!,:se_low]  = results[:,y] .- results.stderror
        results[!,:se_high] = results[:,y] .+ results.stderror
    end
    
    # check if mappings exist
    
    if string(color) ∉ names(results)
        color != :coefname ? @error("user specified color=$color not found in DataFrame") : nothing
        color = 1
    end
    if string(col) ∉ names(results)
        col != :basisname ? @error("user specified col=$col not found in DataFrame") : nothing
        col = 1
    end
    if string(row) ∉ names(results)
        row != :group ? error("user specified row=$row not found in DataFrame") : nothing
        row = 1
    end

    m = mapping(color=color,col=col,row=row;kwargs...)

    m_li = mapping(:time,y)

    basic =  visual(Lines) * m_li
    
    if stderror
        m_se = mapping(:time,:se_low,:se_high)
        basic = basic + visual(Band,alpha=0.5)*m_se
    end

    basic = basic*data(results)
       
    
    

    # add the pvalues
    if !isempty(pvalue)
        p = deepcopy(pvalue)

        # for now, add them to the fixed effect
        if "group" ∉  names(p)
            # group not specified using first
            if "group" ∈  names(results)
                p[!,:group] .= results[1,:group]
                if length(unique(results.group))>1
                    @warn "multiple groups found, choosing first one"
                end
            else
                p[!,:group] .= 1
            end
        end
        

        # rename to match the res-dataframe

        shouldHave = hcat(col,row,color)
        shouldHave = shouldHave[shouldHave.!=1] # remove defaults as defined above
        if ~isempty(kwargs)
             shouldHave = hcat(shouldHave,(values(kwargs)))
        end
        shouldHave = string.(shouldHave)
        
        for k in shouldHave
            if k ∉ names(p)
                p[!,k] .= results[1,k]
            end

        end

        @show shouldHave
        un = unique(p[!,color])
        # define an index to dodge the lines vertically
        p[!,:sigindex] .=  [findfirst(un .== x) for x in p.coefname]
        
        scaleY = [minimum(results.estimate),maximum(results.estimate)]
        stepY = scaleY[2]-scaleY[1]
        posY = stepY*-0.05+scaleY[1]
        Δt = diff(results.time[1:2])[1]
        Δy = 0.01
        p[!,:segments] = [Makie.Rect(Makie.Vec(x,posY+stepY*(Δy*(n-1))),Makie.Vec(y-x+Δt,0.5*Δy*stepY)) for (x,y,n) in zip(p.from,p.to,p.sigindex)]
        basic =  basic + (data(p)*mapping(:segments)*visual(Poly))
    end

    # draw it!

    d = basic*m|> draw
    return d
    
end

function eegHeadMatrix(positions, center, radius)
    oldCenter = mean(positions)
    oldRadius, _ = findmax(x-> norm(x .- oldCenter), positions)
    radF = radius/oldRadius
    return Makie.Mat4f(radF, 0, 0, 0,
                       0, radF, 0, 0,
                       0, 0, 1, 0,
                       center[1]-oldCenter[1]*radF, center[2]-oldCenter[2]*radF, 0, 1)
end

function topoplotLegend(f, allPositions)    
    # for testing
    # data, positions = TopoPlots.example_data()
    
    allPositions = unique(allPositions)

    topoMatrix = eegHeadMatrix(allPositions, (0.5, 0.5), 0.5)

    # colorscheme where first entry is 0, and exactly length(positions)+1 entries
    specialColors = ColorScheme(vcat(RGB(1,1,1.),[posToColor(pos) for pos in allPositions]...))
    
    axis = Axis(f, bbox = BBox(0, 78, 0, 78))
    
	xlims!(low = -0.2, high = 1.2)
	ylims!(low = -0.2, high = 1.2)
    topoplot = eeg_topoplot!(axis, 1:length(allPositions), # go from 1:npos
        string.(1:length(allPositions)); 
        positions=allPositions,
        interpolation=NullInterpolator(), # inteprolator that returns only 0
        colorrange = (0,length(allPositions)), # add the 0 for the white-first color
        colormap= specialColors,
        head = (color=:black, linewidth=1, model = topoMatrix))

    hidedecorations!(current_axis())
    hidespines!(current_axis())

    return topoplot;
end

struct NullInterpolator <: TopoPlots.Interpolator
        
end

function (ni::NullInterpolator)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})

    return zeros(length(xrange),length(yrange))
end

function addPvalues(results, config)
    p = deepcopy(config.extraData.pvalue)

    # for now, add them to the fixed effect
    if "group" ∉  names(p)
        # group not specified using first
        if "group" ∈  names(results)
            p[!,:group] .= results[1,:group]
            if length(unique(results.group))>1
                @warn "multiple groups found, choosing first one"
            end
        else
            p[!,:group] .= 1
        end
    end
    

    # rename to match the res-dataframe

    shouldHave = hcat(config.mappingData.col, config.mappingData.row, config.mappingData.color)
    shouldHave = shouldHave[shouldHave.!=1] # remove defaults as defined above
    
    # was present in the example, but crashes the code if executed
    # if ~isempty(config.mappingData)
    #     shouldHave = hcat(shouldHave, values(config.mappingData))
    # end
    
    shouldHave = string.(shouldHave)
    
    for k in shouldHave
        if k ∉ names(p)
            p[!,k] .= results[1,k]
        end

    end
    # return shouldHave
    un = unique(p[!,config.mappingData.color])
    # define an index to dodge the lines vertically
    p[!,:sigindex] .=  [findfirst(un .== x) for x in p.coefname]

    scaleY = [minimum(results.estimate),maximum(results.estimate)]
    stepY = scaleY[2]-scaleY[1]
    posY = stepY*-0.05+scaleY[1]
    Δt = diff(results.time[1:2])[1]
    Δy = 0.01
    p[!,:segments] = [Makie.Rect(Makie.Vec(x,posY+stepY*(Δy*(n-1))),Makie.Vec(y-x+Δt,0.5*Δy*stepY)) for (x,y,n) in zip(p.from,p.to,p.sigindex)]
    return (data(p)*mapping(:segments)*visual(Poly))
end
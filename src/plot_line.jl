using DataFrames
using TopoPlots
using LinearAlgebra

"""
    plot_line(plotData::DataFrame, config::PlotConfig)

Plot a line plot.
## Arguments:
- `plotData::DataFrame`: data for the line plot being visualized.
- `config::PlotConfig`: data of the configuration being applied to the visualization.

## Behavior:
### `config.extraData.stderror`: 
Indicating whether the data estimates should be complemented 
with lower and higher estimates based on the stderror. 
Lower estimates is gained by pointwise subtraction of the stderror from the estimates. 
Higher estimates is gained by pointwise addition of the stderror to the estimates. 
Both estimates are then included in the mapping.
Default is `false`.
### `config.extraData.categoricalColor`:
Indicates whether it should be categorized based on color. 
Every line will get its discrete entry in the legend.
Default is `true`.
### `config.extraData.categoricalGroup`:
Indicates whether it should be categorized based on group.
The legend is a colorbar.
Default is `true`.
Should not be set in conjunction with `config.extraData.categoricalColor`.
### `config.extraData.topoLegend`:
Indicating whether a topo plot is used as a legend.
Default is `false`.
### `config.extraData.pvalue`: TODO
An array of p-values. If array not empty, complement data by adding p-values.
Default is an empty array.

## Return Value:
The figure displaying the line plot.
"""
function plot_line(plotData::DataFrame, config::PlotConfig)
    plot_line!(Figure(), plotData, config)
end

function plot_line!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig)
    plotData = deepcopy(plotData)
    
    config.resolveMappings(plotData)

    # turn "nothing" from group columns into :fixef
    if "group" ∈  names(plotData)
        plotData.group = plotData.group .|> a -> isnothing(a) ? :fixef : a
    end

    # check if stderror values exist and create new collumsn with high and low band
    if "stderror" ∈  names(plotData) && config.extraData.stderror
        plotData.stderror = plotData.stderror .|> a -> isnothing(a) ? 0. : a
        plotData[!,:se_low]  = plotData[:,config.mappingData.y] .- plotData.stderror
        plotData[!,:se_high] = plotData[:,config.mappingData.y] .+ plotData.stderror
    end
    
    # Get topocolors if topoPlot Legend active
    if (config.extraData.topoLegend) 
        allPositions, colors = getTopoColor(plotData, config)
    else
        # Categorical mapping
        # convert color column into string, so no wrong grouping happens
        if config.extraData.categoricalColor && (:color ∈ keys(config.mappingData))
            config.mappingData = merge(config.mappingData,(;color=config.mappingData.color=>nonnumeric))
        end
        # converts group column into string
        if config.extraData.categoricalGroup && (:group ∈ keys(config.mappingData))
            config.mappingData = merge(config.mappingData,(;group=config.mappingData.group=>nonnumeric))
        end
    end

    # pValues will break if x and y are included in this step
    mapp = mapping(;filterNamesOutTuple(config.mappingData, (:x, :y))...)
    
    xy_mapp = mapping(config.mappingData.x, config.mappingData.y)

    basic = visual(Lines; config.visualData...) * xy_mapp

    # add band of sdterrors
    if config.extraData.stderror
        m_se = mapping(config.mappingData.x,:se_low,:se_high)
        basic = basic + visual(Band,alpha=0.5)*m_se
    end
    
    basic = basic * data(plotData)

    # add the pvalues
    if !isempty(config.extraData.pvalue)
        basic =  basic + addPvalues(plotData, config)
    end
    
    plotEquation = basic * mapp

    # add topoLegend if topoPlot Legend active
    if (config.extraData.topoLegend)    
        topoplotLegend(f, allPositions)
        drawing = draw!(f[1,1],plotEquation; palettes=(color=colors,))
    else
        drawing = draw!(f[1,1],plotEquation)
    end

    
    applyLayoutSettings(config; fig = f, drawing = drawing)

    return f
    
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

function addPvalues(plotData, config)
    p = deepcopy(config.extraData.pvalue)



    # for now, add them to the fixed effect
    if "group" ∉  names(p)
        # group not specified using first
        if "group" ∈  names(plotData)
            p[!,:group] .= plotData[1,:group]
            if length(unique(plotData.group))>1
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
            p[!,k] .= plotData[1,k]
        end

    end
    # return shouldHave
    un = unique(p[!,config.mappingData.color])
    # define an index to dodge the lines vertically
    p[!,:sigindex] .=  [findfirst(un .== x) for x in p.coefname]

    scaleY = [minimum(plotData.estimate),maximum(plotData.estimate)]
    stepY = scaleY[2]-scaleY[1]
    posY = stepY*-0.05+scaleY[1]
    Δt = diff(plotData.time[1:2])[1]
    Δy = 0.01
    p[!,:segments] = [Makie.Rect(Makie.Vec(x,posY+stepY*(Δy*(n-1))),Makie.Vec(y-x+Δt,0.5*Δy*stepY)) for (x,y,n) in zip(p.from,p.to,p.sigindex)]
    return (data(p)*mapping(:segments)*visual(Poly))
end
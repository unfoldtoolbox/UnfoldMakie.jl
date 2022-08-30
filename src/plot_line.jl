using DataFrames
using TopoPlots
using LinearAlgebra

"""
    function plot_line(plotData::DataFrame, config::PlotConfig)

Plot a line plot.
## Arguments:
- `plotData::DataFrame`: Data for the plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.

## Extra Data Behavior:

`categoricalColor`:

Default : `true`

Indicates whether the column referenced in mappingData.color should be used nonnumerically.

`categoricalGroup`:

Default: `true`

Indicates whether the column referenced in mappingData.group should be used nonnumerically.

`topoLegend`:

Default : `false`

Indicating whether a topo plot is used as a legend.

`stderror`:

Default : `false`

Indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 

`pvalue`:

Default : `[]`

An array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values.

## Return Value:
A figure displaying the line plot.

"""
function plot_line(plotData::DataFrame, config::PlotConfig)
    plot_line!(Figure(), plotData, config)
end


"""
    function plot_line!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig)

Plot a line plot.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: Data for the line plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.

## Extra Data Behavior:

`categoricalColor`:

Default : `true`

Indicates whether the column referenced in mappingData.color should be used nonnumerically.

`categoricalGroup`:

Default: `true`

Indicates whether the column referenced in mappingData.group should be used nonnumerically.

`topoLegend`:

Default : `false`

Indicating whether a topo plot is used as a legend.

`stderror`:

Default : `false`

Indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 

`pvalue`:

Default : `[]`

An array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values.

## Return Value:
The input `f`

"""
function plot_line!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig)
    plotData = deepcopy(plotData)
    
    config.resolveMappings(plotData)
    config.setExtraValues
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
        allPositions = getTopoPositions(plotData, config)
        colors = getTopoColor(plotData, config)
        @show allPositions
        @show colors
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
    #mapp = mapping(;filterNamesOutTuple(config.mappingData, (:x, :y))...)
    mapp = mapping(;config.mappingData.color)
    if (:group ∈ keys(config.mappingData))
        mapp = mapp * mapping(;config.mappingData.group)
    end
    
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
        legendRight = config.layoutData.legendPosition == :right
        if config.layoutData.showLegend
            topoAxis = Axis(f[2,2], aspect = DataAspect())
        else
            topoAxis = Axis(legendRight ? f[1:2,2] : f[2,1:2], width = 78, height = 78, aspect = DataAspect())
        end
        topoplotLegend(topoAxis, allPositions)
        mainAxis = Axis(legendRight ? f[1:2,1] : f[1,1:2]; config.axisData...)
        drawing = draw!(mainAxis,plotEquation; palettes=(color=colors,))
    else
        drawing = draw!(Axis(f[1,1]; config.axisData...),plotEquation)
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

function topoplotLegend(axis, allPositions)    
    # for testing
    # data, positions = TopoPlots.example_data()
    
    allPositions = unique(allPositions)

    topoMatrix = eegHeadMatrix(allPositions, (0.5, 0.5), 0.5)

    # colorscheme where first entry is 0, and exactly length(positions)+1 entries
    specialColors = ColorScheme(vcat(RGB(1,1,1.),[posToColor(pos) for pos in allPositions]...))
    
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

    # shouldHave = hcat(config.mappingData.color)
    # shouldHave = shouldHave[shouldHave.!=1] # remove defaults as defined above
    
    # was present in the example, but crashes the code if executed
    # if ~isempty(config.mappingData)
    #     shouldHave = hcat(shouldHave, values(config.mappingData))
    # end
    
    # shouldHave = string.(shouldHave)
    
    # for k in shouldHave
    #     if k ∉ names(p)
    #         p[!,k] .= plotData[1,k]
    #     end
    # end
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
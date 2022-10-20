using DataFrames
using TopoPlots
using LinearAlgebra
"""
    function plot_erp!(f::Union{GridPosition, Figure}, plotData::DataFrame, [config::PlotConfig];kwargs...)
    function plot_erp(plotData::DataFrame, [config::PlotConfig];kwargs...)
        

Plot an ERP plot.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: Data for the line plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
- `kwargs...`: Additional styling behavior. Often used: `plot_erp(df;setMappingValues=(;color=:coefname,col=:conditionA))`
## Extra Data Behavior (...;setExtraData=(;[key]=value)):

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
plot_erp(plotData::DataFrame, config::PlotConfig;kwargs...) = plot_erp!(Figure(), plotData, config;kwargs...)
plot_erp(plotData::DataFrame;kwargs...) = plot_erp!(Figure(), plotData, PlotConfig(:erp);kwargs...)


"""
Plot Butterfly

see `plot_erp`
"""
plot_butterfly(plotData::DataFrame;kwargs...) = plot_erp(plotData, PlotConfig(:butterfly);kwargs...)
plot_butterfly!(f::Union{GridPosition, Figure},plotData::DataFrame;kwargs...) = plot_erp!(f,plotData, PlotConfig(:butterfly);kwargs...)



function plot_erp!(f::Union{GridPosition, Figure}, plotData::DataFrame, config::PlotConfig;kwargs...)
    plotData = deepcopy(plotData)
    
    # set PlotDefaults      
    config.setMappingValues!(color=(:color, :coefname),)
    config.setLayoutValues!(hidespines = (:r, :t))

    config_kwargs!(config;kwargs...)

    # apply config kwargs
    

    # resolve columns with data
    config.mappingData = resolveMappings(plotData,config.mappingData)

    
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
    
    # Get topocolors for butterfly
    if (config.plotType == :butterfly)
    
        allPositions = getTopoPositions(plotData, config)
        colors = getTopoColor(plotData, config)
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


    mapp = mapping()

    if (:color ∈ keys(config.mappingData))
        mapp = mapp * mapping(;config.mappingData.color)
    end
    
    if (:group ∈ keys(config.mappingData))
        mapp = mapp * mapping(;config.mappingData.group)
    end
    
    #remove mapping values with `nothing`
    
    deleteNothing(nt::NamedTuple{names}, keys) where names = NamedTuple{filter(x -> x ∉ keys, names)}(nt)
    config.mappingData = deleteNothing(config.mappingData,keys(config.mappingData)[findall(isnothing.(values(config.mappingData)))])

    xy_mapp = mapping(config.mappingData.x, config.mappingData.y;config.mappingData...)

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

    f_grid = f[1,1]
    # butterfly plot is drawn slightly different
    if config.plotType == :butterfly
        # add topoLegend
    
        if (config.extraData.topoLegend)
            legendRight = config.layoutData.legendPosition == :right
            if config.layoutData.showLegend
                topoAxis = Axis(f[2,2], aspect = DataAspect())
            else
                topoAxis = Axis(legendRight ? f[1:2,2] : f[2,1:2], width = 78, height = 78, aspect = DataAspect())
            end
            topoplotLegend(config,topoAxis, allPositions)
            mainAxis = Axis(legendRight ? f[1:2,1] : f[1,1:2]; config.axisData...)
        else
            # no extra legend
            mainAxis = Axis(f_grid; config.axisData...)
        end
        drawing = draw!(mainAxis,plotEquation; palettes=(color=colors,))
    else
        # normal lineplot draw
        #drawing = draw!(Axis(f[1,1]; config.axisData...),plotEquation)
    
        drawing = draw!(f_grid,plotEquation;axis=config.axisData)
    end

    
    # apply to axis (or axes in case of col/row)
    
    for ax in f.content
         if ax isa Axis
            applyLayoutSettings(config; fig = f, ax=ax, drawing = drawing)
         end
    end

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

function topoplotLegend(config,axis, allPositions)    
    allPositions = unique(allPositions)

    topoMatrix = eegHeadMatrix(allPositions, (0.5, 0.5), 0.5)

    # colorscheme where first entry is 0, and exactly length(positions)+1 entries
    specialColors = ColorScheme(vcat(RGB(1,1,1.),[config.extraData.topoPositionToColorFunction(pos) for pos in allPositions]...))
    
	xlims!(low = -0.2, high = 1.2)
	ylims!(low = -0.2, high = 1.2)
    topoplot = eeg_topoplot!(axis, 1:length(allPositions), # go from 1:npos
        string.(1:length(allPositions)); 
        positions=allPositions,
        interpolation=NullInterpolator(), # inteprolator that returns only 0, which is put to white in the specialColorsmap
        colorrange = (0,length(allPositions)), # add the 0 for the white-first color
        colormap= specialColors,
        head = (color=:black, linewidth=1, model = topoMatrix),
        label_scatter=(markersize=8, strokewidth=0.5,))

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
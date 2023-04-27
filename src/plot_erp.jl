using DataFrames
using TopoPlots
using LinearAlgebra
"""
    function plot_erp!(f::Union{GridPosition, Figure}, plotData::DataFrame;kwargs...)
    function plot_erp(plotData::DataFrame, ;kwargs...)
        

Plot an ERP plot.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::DataFrame`: Data for the line plot visualization.
- `kwargs...`: Additional styling behavior. Often used: `plot_erp(df;mapping=(;color=:coefname,col=:conditionA))`
## Extra Data Behavior (...;extra=(;[key]=value)):
`categoricalColor` (bool,`true`) - Indicates whether the column referenced in mapping.color should be used nonnumerically.
`categoricalGroup` (bool,`true`) - Indicates whether the column referenced in mapping.group should be used nonnumerically.
`topoLegend` (bool, `false`) - Indicating whether a topo plot is used as a legend.
`stderror` (bool,`false`) - Indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 
`pvalue` (Array,[]) - An array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values.

## Return Value:
f - Figure() or the inputed `f`

"""
plot_erp(plotData::DataFrame;kwargs...) = plot_erp!(Figure(), plotData, ;kwargs...)

"""
Plot Butterfly

see `plot_erp`
"""
plot_butterfly(plotData::DataFrame;kwargs...) = plot_butterfly!(Figure(),plotData; kwargs...)
plot_butterfly!(f::Union{GridPosition, <:Figure},plotData::DataFrame;extra=(;),kwargs...) = plot_erp!(f,plotData,;extra= merge((;butterfly=true),extra),kwargs...)



function plot_erp!(f::Union{GridPosition, Figure}, plotData::DataFrame;positions=nothing,labels=nothing,kwargs...)
    config = PlotConfig(:erp)
    config_kwargs!(config;kwargs...)
    if config.extra.butterfly
        config = PlotConfig(:butterfly)
        config_kwargs!(config;kwargs...)
    end


    plotData = deepcopy(plotData) # XXX why?
    
    # resolve columns with data
    config.mapping = resolveMappings(plotData,config.mapping)
    #remove mapping values with `nothing`
    deleteKeys(nt::NamedTuple{names}, keys) where names = NamedTuple{filter(x -> x ∉ keys, names)}(nt)
    config.mapping = deleteKeys(config.mapping,keys(config.mapping)[findall(isnothing.(values(config.mapping)))])
    
    
    # turn "nothing" from group columns into :fixef
    if "group" ∈  names(plotData)
        plotData.group = plotData.group .|> a -> isnothing(a) ? :fixef : a
    end

    # check if stderror values exist and create new collumsn with high and low band
    if "stderror" ∈  names(plotData) && config.extra.stderror
        plotData.stderror = plotData.stderror .|> a -> isnothing(a) ? 0. : a
        plotData[!,:se_low]  = plotData[:,config.mapping.y] .- plotData.stderror
        plotData[!,:se_high] = plotData[:,config.mapping.y] .+ plotData.stderror
    end
    
    # Get topocolors for butterfly
    if (config.extra.butterfly)
        if isnothing(positions) && isnothing(labels)
            config.extra=merge(config.extra,(;topoLegend=false))
            #colors =config.visual.colormap# get(colorschemes[config.visual.colormap],range(0,1,length=nrow(plotData)))
            colors = nothing
            #config.mapping = merge(config.mapping,(;color=config.))
        else
            allPositions = getTopoPositions(;positions=positions,labels=labels)
            colors = getTopoColor(allPositions, config)
        end
    
        
    end
     # Categorical mapping
        # convert color column into string, so no wrong grouping happens
        if config.extra.categoricalColor && (:color ∈ keys(config.mapping))
            config.mapping = merge(config.mapping,(;color=config.mapping.color=>nonnumeric))
        end
       
    # converts group column into string
    if config.extra.categoricalGroup && (:group ∈ keys(config.mapping))
        config.mapping = merge(config.mapping,(;group=config.mapping.group=>nonnumeric))
    end
    #@show colors
    mapp = mapping()

    if (:color ∈ keys(config.mapping))
        mapp = mapp * mapping(;config.mapping.color)
    end
    
    if (:group ∈ keys(config.mapping))
        mapp = mapp * mapping(;config.mapping.group)
    end
    
    

    
    
    # remove x / y
    mappingOthers = deleteKeys(config.mapping,[:x,:y])
    
    xy_mapp = mapping(config.mapping.x, config.mapping.y;mappingOthers...)

    basic = visual(Lines; config.visual...) * xy_mapp
    # add band of sdterrors
    if config.extra.stderror
        m_se = mapping(config.mapping.x,:se_low,:se_high)
        basic = basic + visual(Band,alpha=0.5)*m_se
    end
    
    basic = basic * data(plotData)

    # add the pvalues
    if !isempty(config.extra.pvalue)
        basic =  basic + addPvalues(plotData, config)
    end
    
    plotEquation = basic * mapp
    
    f_grid = f[1,1]
    # butterfly plot is drawn slightly different
    if config.extra.butterfly
        # add topoLegend
    
        if (config.extra.topoLegend)
            topoAxis = Axis(f_grid,width=Relative(0.25),height=Relative(0.25),halign=0.05,valign=0.95,aspect=1)
            topoplotLegend(config,topoAxis, allPositions)
        end
            # no extra legend
            mainAxis = Axis(f_grid; config.axis...)
        
        if isnothing(colors)
            drawing = draw!(mainAxis,plotEquation)
        else
            drawing = draw!(mainAxis,plotEquation; palettes=(color=colors,))
        end
    else
        # normal lineplot draw
        #drawing = draw!(Axis(f[1,1]; config.axisData...),plotEquation)
    
        drawing = draw!(f_grid,plotEquation;axis=config.axis)
        
    end
    applyLayoutSettings!(config; fig = f, ax=drawing,drawing=drawing)#, drawing = drawing)
    
    
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
    specialColors = ColorScheme(vcat(RGB(1,1,1.),[config.extra.topoPositionToColorFunction(pos) for pos in allPositions]...))
    
	xlims!(low = -0.2, high = 1.2)
	ylims!(low = -0.2, high = 1.2)
    topoplot = eeg_topoplot!(axis, 1:length(allPositions), # go from 1:npos
        string.(1:length(allPositions)); 
        positions=allPositions,
        interpolation=NullInterpolator(), # inteprolator that returns only 0, which is put to white in the specialColorsmap
        colorrange = (0,length(allPositions)), # add the 0 for the white-first color
        colormap= specialColors,
        head = (color=:black, linewidth=1, model = topoMatrix),
        label_scatter=(markersize=10, strokewidth=0.5,))

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
    p = deepcopy(config.extra.pvalue)

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
    @show config.mapping
    if :color ∈ keys(config.mapping) 
        c = config.mapping.color isa Pair ? config.mapping.color[1] : config.mapping.color
        un = unique(p[!,c])
        p[!,:sigindex] .=  [findfirst(un .== x) for x in p.coefname]
    else
        p[!,:signindex] .= 1
    end
    # define an index to dodge the lines vertically

    scaleY = [minimum(plotData.estimate),maximum(plotData.estimate)]
    stepY = scaleY[2]-scaleY[1]
    posY = stepY*-0.05+scaleY[1]
    Δt = diff(plotData.time[1:2])[1]
    Δy = 0.01
    p[!,:segments] = [Makie.Rect(Makie.Vec(x,posY+stepY*(Δy*(n-1))),Makie.Vec(y-x+Δt,0.5*Δy*stepY)) for (x,y,n) in zip(p.from,p.to,p.sigindex)]
    return (data(p)*mapping(:segments)*visual(Poly))
end
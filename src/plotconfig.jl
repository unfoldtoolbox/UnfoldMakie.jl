
using GeometryBasics
using ColorSchemes: roma
using Makie
using Colors
using ColorSchemes
using ColorTypes

"""
    PlotConfig(<plotname>)
    holds various different fields, that can modify various different plotting aspects.

"""
mutable struct PlotConfig
    figure::NamedTuple
    axis::NamedTuple
    layout::NamedTuple
    mapping::NamedTuple
    visual::NamedTuple
    legend::NamedTuple
    colorbar::NamedTuple
end


function PlotConfig()# defaults
    PlotConfig(
        (;), #figure
        (;), # axis
        (; # layout
            showLegend = true,
            legendPosition = :right,
            xlabelFromMapping = :x,
            ylabelFromMapping = :y,
            useColorbar = false,
        ),
        (#maping
            x = (:time,),
            y = (:estimate, :yhat, :y),
        ),
        (; # visual
            colormap = :roma
        ),
        (;#legend
            orientation = :vertical,
            tellwidth = true,
            tellheight = false,
        ),
        (;#colorbar
            vertical = true,
            tellwidth = true,
            tellheight = false,
        ),
    )

end


"""
Takes a kwargs named tuple of Key => NamedTuple and merges the fields with the defaults
"""
function config_kwargs!(cfg::PlotConfig; kwargs...)
    is_namedtuple = [isa(t,NamedTuple) for t in values(kwargs)]
    @debug is_namedtuple
    @assert(all(is_namedtuple),
    """ Keyword argument specification (kwargs...) Specified config groups must be NamedTuples', but $(keys(kwargs)[.!is_namedtuple]) was not.
    Maybe you forgot the semicolon (;) at the beginning of your specification? Compare these strings:
    
    plot_example(...; layout = (; showColorbar=true))
    
    plot_example(...; layout = (showColorbar=true))
     
    The first is correct and creates a NamedTuple as required. The second is wrong and its call is ignored.""")
    list = fieldnames(PlotConfig)#[:layout,:visual,:mapping,:legend,:colorbar,:axis]
    keyList = collect(keys(kwargs))
    :extra ∈ keyList ? @warn("Extra is deprecated in 0.4 and extra-keyword args have to be used directly as key-word arguments") : ""
    applyTo = keyList[in.(keyList, Ref(list))]
    for k ∈ applyTo
        setfield!(cfg, k, merge(getfield(cfg, k), kwargs[k]))
    end
end




PlotConfig(T::Symbol) = PlotConfig(Val{T}())


function PlotConfig(T::Val{:circeegtopo})
    cfg = PlotConfig(:topoplot)

    config_kwargs!(
        cfg;
        layout = (; showLegend = false),
        colorbar = (; label = "Voltage [µV]", colormap = Reverse(:RdBu)),
        mapping = (;),
        axis = (;
            label = ""
            #backgroundcolor = RGB(0.98, 0.98, 0.98),
        ),
    )
    return cfg
end


function PlotConfig(T::Val{:topoarray})
    cfg = PlotConfig(:erp)

    config_kwargs!(
        cfg;
        layout = (;),
        colorbar = (;),
        mapping = (;),
        axis = (;),
    )
    return cfg
end



function PlotConfig(T::Val{:topoplot})
    cfg = PlotConfig()

    config_kwargs!(
        cfg;
        layout = (
            showLegend = true,
            xlabelFromMapping = nothing,
            ylabelFromMapping = nothing,
            useColorbar = true,
            hidespines = (),
            hidedecorations = (),
        ),
        visual = (;
            contours = (color = :white, linewidth = 2),
            label_scatter = true,
            label_text = true,
            bounding_geometry = Circle,
            colormap = Reverse(:RdBu),
        ),
        mapping = (;
            x = (nothing,),
            positions = (:pos, :positions, :position, nothing), # Point / Array / Tuple
            labels = (:labels, :label, :sensor, nothing), # String
        ),
        axis = (; aspect = DataAspect()),
    )
    return cfg
end
function PlotConfig(T::Val{:topoplotseries})
    cfg = PlotConfig(:topoplot)
    config_kwargs!(
        cfg,
        layout = (useColorbar = true,),
        colorbar = (;
            #height = 300, 
            flipaxis = true, 
            labelrotation = -π/2, 
            label = "Voltage [µV]"
        ), 
        visual = (;
            label_text = false # true doesnt work again
        ),
        mapping = (col = (:time,), row = (nothing,)),
    )
    return cfg
end
function PlotConfig(T::Val{:designmat})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (;
            useColorbar = true,
            xlabelFromMapping = nothing,
            ylabelFromMapping = nothing,
        ),
        axis = (; xticklabelrotation = pi / 8),
    )
    return cfg
end

function PlotConfig(T::Val{:butterfly})
    cfg = PlotConfig(:erp)
    config_kwargs!(
        cfg;
        layout = (; showLegend = false),
        mapping = (;
            color = (:channel, :channels, :trial, :trials),
            positions = (:pos, :positions, :position, :topoPositions, :x, nothing),
            labels = (:labels, :label, :topoLabels, :sensor, nothing),
        ),
    )
    return cfg
end
function PlotConfig(T::Val{:erp})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        mapping = (; color = (:color, :coefname, nothing)),
        layout = (; showLegend = true,  hidespines = (:r, :t)),
        legend = (; framevisible = false),
    )

    return cfg
end
function PlotConfig(T::Val{:erpimage})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (; useColorbar = true),
        colorbar = (; label = "Voltage [µV]", labelrotation = 4.7),
        axis = (xlabel = "Time", ylabel = "Sorted trials"),
        visual = (; colormap = Reverse("RdBu")),
    )
    return cfg
end
function PlotConfig(T::Val{:paracoord})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (;
            xlabelFromMapping = :channel,
            ylabelFromMapping = :y,
            hidespines = (),
            hidedecorations = (; label = false),
        ),
        mapping = (; channel = :channel, category = :category, time = :time),
    )
    return cfg
end

function resolveMappings(plotData, mappingData)
    function isColumn(col)
        string(col) ∈ names(plotData)
    end
    # filter columns to only include the ones that are in plotData, or throw an error if none are
    function getAvailable(key, choices)
        # isColumn is an internally defined function mapping col ∈ names(plotData)
        available = choices[keys(choices)[isColumn.(collect(choices))]]

        if length(available) >= 1
            return available[1]
        else
            return (nothing ∈ collect(choices)) ? # is it allowed to return nothing?
                   nothing :
                   @error(
                "default columns for $key = $choices not found, user must provide one by using plot_plotname(...;mapping=(; $key=:yourColumnName))"
            )
        end
    end
    # have to use Dict here because NamedTuples break when trying to map them with keys/indices
    mappingDict = Dict()
    for (k, v) in pairs(mappingData)

        #if 
        #    continue
        #end
        mappingDict[k] = isa(v, Tuple) ? getAvailable(k, v) : v
    end
    return (; mappingDict...)
end


"""
Val{:bu}() to => :bu
"""
valType_to_symbol(T) = Symbol(split(string(T), [':', '}'])[2])

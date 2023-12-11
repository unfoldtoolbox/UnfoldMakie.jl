
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
            show_legend = true,
            legend_position = :right,
            xlabelFromMapping = :x,
            ylabelFromMapping = :y,
            use_colorbar = false,
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

    is_namedtuple = [isa(t, NamedTuple) for t in values(kwargs)]
    @assert(
        all(is_namedtuple),
        """ Keyword argument specification (kwargs...) Specified config groups must be NamedTuples', but $(keys(kwargs)[.!is_namedtuple]) was not.
        Maybe you forgot the semicolon (;) at the beginning of your specification? Compare these strings:

        plot_example(...; layout = (; use_colorbar=true))

        plot_example(...; layout = (use_colorbar=true))
         
        The first is correct and creates a NamedTuple as required. The second is wrong and its call is ignored."""
    )
    list = fieldnames(PlotConfig) #[:layout, :visual, :mapping, :legend, :colorbar, :axis]

    keyList = collect(keys(kwargs))
    :extra ∈ keyList ?
    @warn(
        "Extra is deprecated in 0.4 and extra-keyword args have to be used directly as key-word arguments"
    ) : ""
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
        layout = (; show_legend = false),
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

    config_kwargs!(cfg; layout = (;), colorbar = (;), mapping = (;), axis = (;))
    return cfg
end



function PlotConfig(T::Val{:topoplot})
    cfg = PlotConfig()

    config_kwargs!(
        cfg;
        layout = (
            show_legend = true,
            xlabelFromMapping = nothing,
            ylabelFromMapping = nothing,
            use_colorbar = true,
            hidespines = (),
            hidedecorations = (Dict(:label => false)),
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
        colorbar = (; flipaxis = true, labelrotation = -π / 2, label = "Voltage [µV]"),
        axis = (; xlabel = "", aspect = DataAspect()),
    )
    return cfg
end
function PlotConfig(T::Val{:topoplotseries})
    cfg = PlotConfig(:topoplot)
    config_kwargs!(
        cfg,
        layout = (use_colorbar = true,),
        colorbar = (; flipaxis = true, labelrotation = -π / 2, label = "Voltage [µV]"), # is it a duplication??
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
            use_colorbar = true,
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
        layout = (; show_legend = false),
        mapping = (;
            color = (:channel, :channels, :trial, :trials),
            positions = (:pos, :positions, :position, :topo_positions, :x, nothing),
            labels = (:labels, :label, :topoLabels, :sensor, nothing),
        ),
        axis = (xlabel = "Time [s]", ylabel = "Voltage [µV]", yticklabelsize = 14),
    )
    return cfg
end
function PlotConfig(T::Val{:erp})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        mapping = (; color = (:color, :coefname, :Conditions, nothing)),
        layout = (; show_legend = true, hidespines = (:r, :t)),
        legend = (; framevisible = false),
        axis = (xlabel = "Time [s]", ylabel = "Voltage [µV]", yticklabelsize = 14),
    )

    return cfg
end
function PlotConfig(T::Val{:erpgrid})
    cfg = PlotConfig()

    config_kwargs!(cfg; layout = (;), colorbar = (;), mapping = (;), axis = (;))
    return cfg
end

function PlotConfig(T::Val{:channelimage})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        #layout = (; use_colorbar = true),
        colorbar = (; label = "Voltage [µV]", labelrotation = 4.7),
        axis = (xlabel = "Time [s]", ylabel = "Channels", yticklabelsize = 14),
        visual = (; colormap = Reverse("RdBu")), #cork
    )
    return cfg
end
function PlotConfig(T::Val{:erpimage})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (; use_colorbar = true),
        colorbar = (; label = "Voltage [µV]", labelrotation = 4.7),
        axis = (xlabel = "Time [s]", ylabel = "Sorted trials"),
        visual = (; colormap = Reverse("RdBu")),
    )
    return cfg
end
function PlotConfig(T::Val{:paracoord})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        visual = (;
            colormap = Makie.wong_colors(),
            color = :black, # default linecolor
            alpha = 0.3, 
        ),
        axis = (; ylabel = "Time"),
        legend = (; merge = true),# fontsize = 14),
        mapping = (; x = :channel),
    )
    return cfg
end

function resolve_mappings(plot_data, mapping_data) # check mapping_data in PlotConfig(T::Val{:erp})
    function is_column(col)
        string(col) ∈ names(plot_data)
    end
    # filter columns to only include the ones that are in plot_data, or throw an error if none are
    function get_available(key, choices)
        # is_column is an internally defined function mapping col ∈ names(plot_data)
        available = choices[keys(choices)[is_column.(collect(choices))]]

        if length(available) >= 1
            return available[1]
        else
            return (nothing ∈ collect(choices)) ? # is it allowed to return nothing?
                   nothing :
                   @error(
                "default columns for $key = $choices not found, 
                user must provide one by using plot_plotname(...; mapping=(; $key=:your_column_name))"
            )
        end
    end
    # have to use Dict here because NamedTuples break when trying to map them with keys/indices
    mapping_dict = Dict()
    for (k, v) in pairs(mapping_data)

        #if 
        #    continue
        #end
        mapping_dict[k] = isa(v, Tuple) ? get_available(k, v) : v
    end
    return (; mapping_dict...)
end


"""
Val{:bu}() to => :bu
"""
valType_to_symbol(T) = Symbol(split(string(T), [':', '}'])[2])

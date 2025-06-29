
using GeometryBasics
using Makie: legend_position_to_aligns
using ColorSchemes: roma
using Makie
using Colors
using ColorSchemes
using ColorTypes

"""
    PlotConfig(<plotname>)

Contains several different fields that can modify various aspects of the plot.
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
            use_colorbar = true,
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
            halign = :right,
            valign = :center,
        ),
        (;#colorbar
            vertical = true,
            tellwidth = true,
            tellheight = false,
            labelrotation = -π / 2,
        ),
    )
end

PlotConfig(T::Symbol) = PlotConfig(Val{T}())


function PlotConfig(T::Val{:circtopos})
    cfg = PlotConfig(:topoplot)

    config_kwargs!(
        cfg;
        layout = (; show_legend = false),
        colorbar = (;
            labelrotation = -π / 2,
            label = "Voltage [µV]",
            colormap = Reverse(:RdBu),
        ),
        mapping = (;),
        axis = (; aspect = 1),
    )
    return cfg
end

function PlotConfig(T::Val{:topoplot})
    cfg = PlotConfig()

    config_kwargs!(
        cfg;
        layout = (
            use_colorbar = true,
            hidespines = (),
            hidedecorations = (Dict(:label => false)),
        ),
        visual = (;
            contours = (color = :white, linewidth = 2),
            enlarge = 1,
            label_scatter = true,
            label_text = false,
            bounding_geometry = Circle,
            colormap = Reverse(:RdBu),
        ),
        mapping = (;
            x = (nothing),
            positions = (:pos, :positions, :position, nothing), # Point / Array / Tuple
            labels = (:labels, :label, :sensor, nothing), # String
        ),
        colorbar = (; flipaxis = true, label = "Voltage [µV]"),
        axis = (; xlabel = "Time", aspect = DataAspect()),
    )
    return cfg
end
function PlotConfig(T::Val{:topoplotseries})
    cfg = PlotConfig(:topoplot)
    config_kwargs!(
        cfg,
        axis = (;
            title = "",
            titlesize = 16,
            titlefont = :bold,
            xlabel = "Time windows",
            ylabel = "",
            ylabelpadding = 25,
            xlabelpadding = 25,
            xpanlock = true,
            ypanlock = true,
            xzoomlock = true,
            yzoomlock = true,
            xrectzoom = false,
            yrectzoom = false,
        ),
        layout = (; use_colorbar = true),
        colorbar = (; flipaxis = true, label = "Voltage [µV]"),
        visual = (;
            label_text = false,
            colormap = Reverse(:RdBu),
            enlarge = 1,
            label_scatter = false,
            levels = nothing,
        ),
        mapping = (; col = (:time,), row = (nothing,)),
    )
    return cfg
end
function PlotConfig(T::Val{:designmat})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (; use_colorbar = true,),
        axis = (;
            xlabel = "Conditions",
            ylabel = "Trials",
            xticklabelrotation = round(pi / 8, digits = 2),
        ),
        colorbar = (; flipaxis = true, label = ""),
    )
    return cfg
end

function PlotConfig(T::Val{:splines})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (;),
        axis = (;),
        visual = (; colormap = :viridis),
        legend = (; title = "Splines", framevisible = false),
    )
    return cfg
end

function PlotConfig(T::Val{:butterfly})
    cfg = PlotConfig(:erp)
    config_kwargs!(
        cfg;
        layout = (;
            show_legend = false,
            hidespines = (:r, :t),
            hidedecorations = (Dict(
                :label => false,
                :ticks => false,
                :ticklabels => false,
            )),
        ),
        mapping = (;
            color = (:channel, :channels, :trial, :trials),
            positions = (:pos, :positions, :position, :topo_positions, :x, nothing),
            labels = (:labels, :label, :topoLabels, :sensor, nothing),
            group = (:channel,),
        ),
        axis = (xlabel = "Time [s]", ylabel = "Voltage [µV]", yticklabelsize = 14),
        visual = (; color = nothing, colormap = nothing),
    )
    return cfg
end

function PlotConfig(T::Val{:erp})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        mapping = (; color = (:color, :coefname, nothing)),
        layout = (;
            use_colorbar = true,
            use_legend = true,
            hidespines = (:r, :t),
            hidedecorations = (Dict(
                :label => false,
                :grid => true,
                :label => false,
                :ticks => false,
                :ticklabels => false,
            )),
        ),
        legend = (; framevisible = false),
        axis = (
            xlabel = "Time [s]",
            ylabel = "Voltage [µV]",
            yticklabelsize = 14,
            xtickformat = "{:.1f}",
        ),
        colorbar = (; label = "", flipaxis = true),
        visual = (; colormap = :roma, color = Makie.wong_colors()),
    )
    return cfg
end

function PlotConfig(T::Val{:erpgrid})
    cfg = PlotConfig()

    config_kwargs!(
        cfg;
        layout = (;),
        colorbar = (;),
        mapping = (;),
        axis = (
            width = Relative(1.05),
            height = Relative(1.05),
        ),
    )
    return cfg
end

function PlotConfig(T::Val{:channelimage})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        #layout = (; use_colorbar = true),
        colorbar = (; label = "Voltage [µV]"),
        axis = (xlabel = "Time", ylabel = "Channels", yticklabelsize = 14),
        visual = (; colormap = Reverse("RdBu")), #cork
    )
    return cfg
end
function PlotConfig(T::Val{:erpimage})
    cfg = PlotConfig()
    config_kwargs!(
        cfg;
        layout = (; use_colorbar = true),
        colorbar = (; label = "Voltage [µV]"),
        axis = (xlabel = "Time", ylabel = "Trials"),
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
        axis = (;
            xlabel = "Channels",
            ylabel = "Voltage [µV]",
            title = "",
            xlabelpadding = 14,
            ylabelpadding = 26,
        ),
        legend = (; title = "Conditions", merge = true, framevisible = false), # fontsize = 14),
        mapping = (; x = :channel),
        layout = (; show_legend = true),
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
                "Default columns for $key = $choices not found, 
                user must provide one by using plot_plotname(...; mapping=(; $key=:your_column_name))"
            )
        end
    end
    # have to use Dict here because NamedTuples break when trying to map them with keys/indices
    mapping_dict = Dict()
    for (k, v) in pairs(mapping_data)
        mapping_dict[k] = isa(v, Tuple) ? get_available(k, v) : v
    end
    return (; mapping_dict...)
end

"""
    config_kwargs!(cfg::PlotConfig; kwargs...)
Takes NamedTuple of `Key => NamedTuple` as kwargs and merges the fields with the defaults.
"""
function config_kwargs!(cfg::PlotConfig; kwargs...)

    is_namedtuple = [isa(t, NamedTuple) for t in values(kwargs)]
    @assert(
        all(is_namedtuple),
        """ Keyword argument specification (kwargs...). Specified config groups must be from `NamedTuple`, but $(keys(kwargs)[.!is_namedtuple]) was not.

        Maybe you forgot the semicolon (;) at the beginning of your specification? Compare these strings:

        plot_example(...; layout = (; use_colorbar = true))

        plot_example(...; layout = (use_colorbar = true))
         
        The first is correct and creates a `NamedTuple` as needed. The second is incorrect and its call is ignored."""
    )
    field_list = fieldnames(PlotConfig) #[:layout, :visual, :mapping, :legend, :colorbar, :axis]
    key_list = collect(keys(kwargs))
    :extra ∈ key_list ?
    @warn(
        "Extra is deprecated in 0.4, and extra keyword arguments must be used directly as keyword arguments."
    ) : ""
    apply_to = key_list[in.(key_list, Ref(field_list))]
    for k ∈ apply_to
        setfield!(cfg, k, merge(getfield(cfg, k), kwargs[k]))
    end
end

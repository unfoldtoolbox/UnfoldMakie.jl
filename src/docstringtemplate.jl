function _docstring(cfgsymb::Symbol)
    #pad = maximum(length(string(f)) for f in fieldnames(T))
    cfg = PlotConfig(cfgsymb)
    fn = fieldnames(PlotConfig)
    out = ""

    visuallink = Dict(
        :erp =>`Makie.lines`,
        :butterfly =>`Makie.lines`,
        :paracoord =>`Makie.lines`,
        :designmat => `Makie.heatmap`,
        :erpimage => `Makie.heatmap`,
        :channelimage => `Makie.heatmap`,
        :circeegtopo => `Topoplot.eeg_topoplot`,
        :topoplot => `Topoplot.eeg_topoplot`,
        :topoplotseries => `Topoplot.eeg_topoplot`
    )
    cbarstring = (cfgsymb == :erp || cfgsymb == :butterfly) ? "[`AlgebraOfGraphics.colobar!`](@ref)" : "[`Makie.Colorbar`](@ref)"
    link = Dict(
        :figure => "use `kwargs...` of [`Makie.Figure`](@ref)",
        :axis => "use `kwargs...` of  [`Makie.Axis`](@ref)",
        :legend => "use `kwargs...` of  [`Makie.Legend`](@ref)",
        :colorbar => "use `kwargs...` of  $cbarstring",
        :visual => "use `kwargs...` of [`$(visuallink[cfgsymb])`](@ref)",
        
    )
    for k = 1:length(fn)
        namedtpl = Base.getfield(cfg,fn[k])
        addlink = ""
        try
            addlink = "- *"*link[fn[k]]*"*"
        catch
        end
        out = out * "**$(fn[k]) =** $(string(namedtpl)) $addlink \n\n"
    end
        
    return """## Shared plot configuration options
        The shared plot options can be used as follows:
        `type=(; key=value,...))` - for example `plot_x(..., layout=(show_legend=true, legend_position=:right))`. 
        Multiple defaults will be cycled until match.

        $(out)
        """
        
  end
  
""" 
    $(TYPEDSIGNATURES)
$(_docstring(:erp))

"""
function plot_new()
    return "b"
end
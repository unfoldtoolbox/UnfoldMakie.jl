function _docstring(cfg_symb::Symbol)
    cfg = PlotConfig(cfg_symb)
    fn = fieldnames(PlotConfig)
    out = ""

    visuallink = Dict(
        :erp => `Makie.lines`,
        :butterfly => `Makie.lines`,
        :paracoord => `Makie.lines`,
        :erpgrid => `Makie.lines`,
        :designmat => `Makie.heatmap`,
        :erpimage => `Makie.heatmap`,
        :channelimage => `Makie.heatmap`,
        :circtopos => `Topoplot.eeg_topoplot`,
        :topoplot => `Topoplot.eeg_topoplot`,
        :topoplotseries => `Topoplot.eeg_topoplot`,
    )
    visuallink2 = Dict(
        :erp => "https://docs.makie.org/stable/reference/plots/lines/",
        :butterfly => "https://docs.makie.org/stable/reference/plots/lines/",
        :paracoord => "https://docs.makie.org/stable/reference/plots/lines/",
        :erpgrid => "https://docs.makie.org/stable/reference/plots/lines/",
        :designmat => "https://docs.makie.org/stable/reference/plots/heatmap/",
        :erpimage => "https://docs.makie.org/stable/reference/plots/heatmap/",
        :channelimage => "https://docs.makie.org/stable/reference/plots/heatmap/",
        :circtopos => "https://makieorg.github.io/TopoPlots.jl/stable/eeg/",
        :topoplot => "https://makieorg.github.io/TopoPlots.jl/stable/eeg/",
        :topoplotseries => "https://makieorg.github.io/TopoPlots.jl/stable/eeg/",
    )
    cbarstring =
        (cfg_symb == :erp || cfg_symb == :butterfly) ?
        "[`AlgebraOfGraphics.colobar!`](@ref)" :
        "[`Makie.Colorbar`](https://docs.makie.org/stable/reference/blocks/colorbar/)"
    link = Dict(
        :figure => "use `kwargs...` of [`Makie.Figure`](https://docs.makie.org/stable/explanations/figure/)",
        :axis => "use `kwargs...` of  [`Makie.Axis`](https://docs.makie.org/stable/reference/blocks/axis/)",
        :legend => "use `kwargs...` of  [`Makie.Legend`](https://docs.makie.org/stable/reference/blocks/legend/)",
        :colorbar => "use `kwargs...` of  $cbarstring",
        :visual => "use `kwargs...` of [$(visuallink[cfg_symb])]($(visuallink2[cfg_symb]))",
    )
    for k = 1:length(fn)
        namedtpl = string(Base.getfield(cfg, fn[k]))
        addlink = ""
        try
            addlink = "- *" * link[fn[k]] * "*"
        catch
        end
        namedtpl = replace(namedtpl, "_" => "\\_")
        out = out * "**$(fn[k]) =** $(namedtpl) $addlink \n\n"
    end

    return """## Shared plot configuration options
        The shared plot options can be used as follows: `type = (; key = value, ...))`.  
        For example `plot_x(...; layout = (; show_legend = true, legend_position = :right))`.  
        Multiple defaults will be cycled until match.

        Placing `;` is important!

        $(out)
        """
end
#= 
""" 
    $(TYPEDSIGNATURES)
$(_docstring(:erp))

"""
function plot_new()
    return "b"
end =#

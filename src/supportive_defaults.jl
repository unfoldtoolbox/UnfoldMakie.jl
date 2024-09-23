
"""
    supportive_defaults(cfg_symb::Symbol)

Default configurations for the supporting axis. Similar to PlotConfig, but these configurations are not shared by all plots.\\
Such supporting axes allow users to flexibly see defaults in docstrings and manipulate them using corresponding axes.
    
For developers: to make them updateable in the function, use `update_axis`.
**Return value:** `NamedConfig`.
"""
function supportive_defaults(cfg_symb::Symbol)
    # plot_splines
    if cfg_symb == :spline_default
        return (;
            ylabel = "Spline value",
            xlabelvisible = false,
            xticklabelsvisible = false,
            ylabelvisible = true,
        )
    elseif cfg_symb == :density_default
        return (; xautolimitmargin = (0, 0), ylabel = "Density value")
    elseif cfg_symb == :superlabel_default
        return (; fontsize = 20, padding = (0, 0, 40, 0))
        # plot_butterfly
    elseif cfg_symb == :topo_default
        return (;
            width = Relative(0.35),
            height = Relative(0.35),
            halign = 0.05,
            valign = 0.95,
            aspect = 1,
        )
        # plot_erpimage
    elseif cfg_symb == :meanplot_default
        return (;
            height = 100,
            xlabel = "Time [s]",
            xlabelpadding = 0,
            xautolimitmargin = (0, 0),
        )
    elseif cfg_symb == :sortplot_default
        return (; ylabelvisible = true, yticklabelsvisible = false)
        # plot_erpgrid
    elseif cfg_symb == :hlines_grid_default
        return (; color = :gray, linewidth = 0.5)
    elseif cfg_symb == :vlines_grid_default
        return (; color = :gray, linewidth = 0.5, ymin = 0.2, ymax = 0.8)
    elseif cfg_symb == :lines_grid_default
        return (; color = :deepskyblue3)
    elseif cfg_symb == :labels_grid_default
        return (; color = :gray, fontsize = 12, align = (:left, :top), space = :relative)
    end
end

"""
    update_axis(support_axis::NamedTuple; kwargs...)
Update values of `NamedTuple{key = value}`.\\
Used for supportive axes to make users be able to flexibly change them.
"""
function update_axis(support_axis::NamedTuple; kwargs...)
    support_axis = (; support_axis..., kwargs...)
    return support_axis
end

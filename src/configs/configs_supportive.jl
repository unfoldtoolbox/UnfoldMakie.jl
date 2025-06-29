
"""
    supportive_defaults(cfg_symb::Symbol)

Default configurations for the supporting axis. Similar to PlotConfig, but these configurations are not shared by all plots.\\
Such supporting axes allow users to flexibly see defaults in docstrings and manipulate them using corresponding axes.
    
For developers: to make them updateable in the function, use `update_axis`.
**Return value:** `NamedTuple`.
"""
function supportive_defaults(cfg_symb::Symbol; docstring = false)
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
        # plot_erp
    elseif cfg_symb == :erp_significance_l_default
        return (; alpha = 1, linewidth = 0.005, gap = 0.1)
    elseif cfg_symb == :erp_significance_v_default
        return (; alpha = 0.3)
    elseif cfg_symb == :superlabel_default
        return (; fontsize = 20, padding = (0, 0, 40, 0))

        # plot_butterfly
    elseif cfg_symb == :topo_default_single_butterfly
        return (;
            width = Relative(0.35),
            height = Relative(0.35),
            halign = 0.05,
            valign = 0.95,
            aspect = 1,
        )
    elseif cfg_symb == :topo_default_single_circular
        return (;
            width = Relative(0.2), # size of bboxes
            height = Relative(0.2),
            aspect = 1,
        )
    elseif cfg_symb == :topo_default_attributes_butterfly
        return (;
            head = (color = :black, linewidth = 1),
            label_scatter = (markersize = 10, strokewidth = 0.5),
            interpolation = NullInterpolator(),
        )
        # plot_erpimage
    elseif cfg_symb == :meanplot_default
        return (;
            height = 100,
            xlabel = "Time",
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
    elseif cfg_symb == :subaxes_default
        return (; width = Relative(0.1), height = Relative(0.1))
    elseif cfg_symb == :labels_grid_default
        return (; color = :gray, fontsize = 12, align = (:left, :top), space = :relative)
    elseif cfg_symb == :indicator_grid_default
        return (; fontsize = 12,
            xlim = [-0.04, 1], ylim = [-0.04, 1],
            arrows_start = [Point2f(0), Point2f(0)], # Define the starting points for arrows (origin at (0, 0) for both directions)
            arrows_dir = [Vec2f(0, 0.1), Vec2f(0.1, 0)], # Define the direction vectors for the arrows (one pointing right and the other pointing up)
            arrows_kwargs = (arrowsize = 10,), # Size of the arrows
            text_x_coords = (0.02, 0),
            text_x_kwargs = (text = "Time [s]", align = (:left, :top), fontsize = 12),
            text_y_coords = (-0.008, 0.01),
            text_y_kwargs = (
                text = "Voltage [µV]",
                align = (:left, :baseline),
                fontsize = 12,
                rotation = π / 2,
            ),
        )

        # plot_topoplot 
    elseif cfg_symb == :topo_default_single
        return (;
            width = Relative(1),
            height = Relative(1),
            halign = 0.05,
            valign = 0.95,
            aspect = DataAspect(),
        )
    elseif cfg_symb == :topo_default_attributes
        if docstring == false
            return (;
                interp_resolution = (128, 128),
                interpolation = CloughTocher(),
                label_scatter = (;),
            )
        else
            return string("interp_resolution = (128, 128), interpolation = CloughTocher()")
        end
        # plot_topoplotseries
    elseif cfg_symb == :topo_default_series
        return (;
            aspect = 1,
            title = "",
            xgridvisible = false,
            xminorgridvisible = false,
            xminorticksvisible = false,
            xticksvisible = false,
            xticklabelsvisible = false,
            xlabelvisible = true,
            ygridvisible = false,
            yminorgridvisible = false,
            yminorticksvisible = false,
            yticksvisible = false,
            yticklabelsvisible = false,
            #ylabelvisible = false,
            leftspinevisible = false,
            rightspinevisible = false,
            topspinevisible = false,
            bottomspinevisible = false,
            xpanlock = true,
            ypanlock = true,
            xzoomlock = true,
            yzoomlock = true,
            xrectzoom = false,
            yrectzoom = false,
        )
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

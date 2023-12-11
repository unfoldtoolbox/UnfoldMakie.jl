function apply_layout_settings!(config::PlotConfig; fig=nothing, hm=nothing,
    drawing=nothing, ax=nothing, plotArea=(1, 1))
    if isnothing(ax)
        ax = current_axis()
    end

    if (config.layout.show_legend)
        if isnothing(fig)
            @error "Legend needs figure parameter"
        else
            # set f[] position depending on legend_position
            legend_position = config.layout.legend_position == :right ? fig[1:plotArea[1], plotArea[2]+1] : fig[plotArea[1]+1, 1:plotArea[2]]
            if isnothing(drawing)
                if (config.layout.use_colorbar)
                    if isnothing(hm)
                        Colorbar(legend_position; colormap=config.visual.colormap, config.colorbar...)
                    else
                        Colorbar(legend_position, hm; config.colorbar...)
                    end
                else
                    Legend(legend_position, ax, "Conditions"; config.legend...)
                end
            else
                legend!(legend_position, drawing; config.legend...)
                colorbar!(legend_position, drawing; config.colorbar...)
            end
        end
    end

    if :hidespines ∈ keys(config.layout) && !isnothing(config.layout.hidespines)
        Makie.hidespines!(ax, config.layout.hidespines...)
    end

    if :hidedecorations ∈ keys(config.layout) && !isnothing(config.layout.hidedecorations)
        hidedecorations!(ax; config.layout.hidedecorations...)
    end

    # automatic labels
    #if !isnothing(config.layout.xlabelFromMapping)
    #    ax.xlabel = string(config.mapping[config.layout.xlabelFromMapping])
    #end
    #if !isnothing(config.layout.ylabelFromMapping)
    #    ax.ylabel = string(config.mapping[config.layout.ylabelFromMapping])
    #end
end
Makie.hidedecorations!(ax::Matrix{AxisEntries}; kwargs...) = Makie.hidedecorations!.(ax; kwargs...)
Makie.hidespines!(ax::Matrix{AxisEntries}, args...) = Makie.hidespines!.(ax, args...)

#hidedecorations!(ax::AxisEntries;kwargs...) = Makie.hidedecorations!.(ax.axis;kwargs...)
Makie.hidespines!(ax::AxisEntries, args...) = Makie.hidespines!.(ax.axis, args...)
#hidespinses!(ax:Axis,args...) = hiespines!.(Ref(ax),args...)
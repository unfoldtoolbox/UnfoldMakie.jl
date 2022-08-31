function applyLayoutSettings(config::PlotConfig; fig = nothing, hm = nothing, drawing = nothing, ax = nothing, plotArea = (1, 1))
    # remove border
    if isnothing(ax)
        ax = current_axis()
    end

    if !config.layoutData.border
        hidespines!(ax, :t, :r)
    end

    # set f[] position depending on legendPosition
    if (config.layoutData.showLegend)
        if isnothing(fig)
            @error "Legend needs figure parameter"
        else
            legendPosition = config.layoutData.legendPosition == :right ? fig[1:plotArea[1], plotArea[2]+1] : fig[plotArea[1]+1, 1:plotArea[2]];
            if isnothing(drawing)
                if(config.layoutData.useColorbar)
                    if isnothing(hm)
                        Colorbar(legendPosition; colormap=config.visualData.colormap, config.colorbarData...)
                    else
                        Colorbar(legendPosition, hm; config.colorbarData...)
                    end
                else
                    Legend(legendPosition, ax; config.legendData...)
                end
            else
                legend!(legendPosition, drawing; config.legendData...)
                colorbar!(legendPosition, drawing; config.colorbarData...)
            end
        end
    end
    
    # labels
    if config.layoutData.showAxisLabels
        ax.xlabel = config.layoutData.xlabel === nothing ? string(config.mappingData.x) : config.layoutData.xlabel
        ax.ylabel = config.layoutData.ylabel === nothing ? string(config.mappingData.y) : config.layoutData.ylabel
    end

    if !isnothing(config.layoutData.ylims)
        ylims!(config.layoutData.ylims...)
    end

    if !isnothing(config.layoutData.xlims)
        xlims!(config.layoutData.xlims...)
    end
end
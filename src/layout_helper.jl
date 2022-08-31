function applyLayoutSettings(config::PlotConfig; fig = nothing, hm = nothing, drawing = nothing, ax = nothing, plotArea = (1, 1))
    if isnothing(ax)
        ax = current_axis()
    end

    if (config.layoutData.showLegend)
        if isnothing(fig)
            @error "Legend needs figure parameter"
        else
            # set f[] position depending on legendPosition
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

    if :hidespines ∈ keys(config.layoutData) && !isnothing(config.layoutData.hidespines)
        hidespines!(ax, config.layoutData.hidespines...)
    end
    
    if :hidedecorations ∈ keys(config.layoutData) && !isnothing(config.layoutData.hidedecorations)
        hidedecorations!(ax; config.layoutData.hidedecorations...)
    end
    
    # automatic labels
    if !isnothing(config.layoutData.xlabelFromMapping)
        ax.xlabel = string(config.mappingData[config.layoutData.xlabelFromMapping])
    end
    if !isnothing(config.layoutData.ylabelFromMapping)
        ax.ylabel = string(config.mappingData[config.layoutData.ylabelFromMapping])
    end
end
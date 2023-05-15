function applyLayoutSettings!(config::PlotConfig; fig = nothing, hm = nothing, 
                            drawing = nothing, ax = nothing, plotArea = (1, 1))
    if isnothing(ax)
        ax = current_axis()
    end

    if (config.layout.showLegend)
        if isnothing(fig)
            @error "Legend needs figure parameter"
        else
            # set f[] position depending on legendPosition
            legendPosition = config.layout.legendPosition == :right ? fig[1:plotArea[1], plotArea[2]+1] : fig[plotArea[1]+1, 1:plotArea[2]];
            if isnothing(drawing)
                if(config.layout.useColorbar)
                    if isnothing(hm)
                        Colorbar(legendPosition; colormap=config.visual.colormap, config.colorbar...)
                    else
                        Colorbar(legendPosition, hm; config.colorbar...)
                    end
                else
                    Legend(legendPosition, ax; config.legend...)
                end
            else
                legend!(legendPosition, drawing; config.legend...)
                colorbar!(legendPosition, drawing; config.colorbar...)
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
Makie.hidedecorations!(ax::Matrix{AxisEntries};kwargs...) = Makie.hidedecorations!.(ax;kwargs...)
Makie.hidespines!(ax::Matrix{AxisEntries},args...) = Makie.hidespines!.(ax,args...)
#hidespinses!(ax:Axis,args...) = hiespines!.(Ref(ax),args...)
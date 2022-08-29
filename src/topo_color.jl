# Work in progress

function getTopoPositions(plotData, config)

    if isnothing(config.mappingData.topoPositions)
        if isnothing(config.mappingData.topoLabels)
            if isnothing(config.mappingData.topoChannels)
                @error "At least one of these collumns is required: topoChannels, topoLabels, topoPositions"
            else
                plotData.topoLabels = plotData[:, config.mappingData.topoChannels] .|> channelToLabel
                config.setMappingValues(topoLabels = :topoLabels)
            end
        end
        plotData.topoPositions = plotData[:, config.mappingData.topoLabels] .|> getLabelPos
        config.setMappingValues(topoPositions = :topoPositions)
    end

    unique(plotData[:, config.mappingData.topoPositions] .|> (p -> Point2f(p[1], p[2])))
end

function getTopoColor(plotData, config)

    if !isnothing(config.mappingData.topoLabels)
        config.setMappingValues(color=config.mappingData.topoLabels)
        list = zip(plotData[:, config.mappingData.topoLabels], plotData[:, config.mappingData.topoPositions])
        mapping = unique(list .|> entry -> entry[1]=>posToColor(entry[2]))
    elseif !isnothing(config.mappingData.topoPositions)
        config.setMappingValues(color=:positionLabel)
        plotData.positionLabel = plotData[:, config.mappingData.topoPositions] .|> string
        mapping = unique(plotData[:, config.mappingData.topoPositions] .|> entry -> string(entry)=>posToColor(entry))
    else
        mapping = nothing
    end

    # if !isnothing(config.mappingData.topoPositions)
    #     @show "Test1"
    #     config.mappingData = merge(config.mappingData, (;color=:customLabels))
    #     # create own label data column
    #     results.customLabels = results[:, config.mappingData.topoPositions] .|> customLabelPipe
    #     mapping = unique(zip(results.customLabels, results[:, config.mappingData.topoPositions]) .|> data -> (data[1]=>posToColor(data[2])))
    # elseif !isnothing(config.mappingData.topoLabels)
    #     @show "Test2"
    #     config.mappingData = merge(config.mappingData, (;color=config.mappingData.topoLabels))

    #     mapping = unique(results[:, config.mappingData.topoLabels] .|> labelPipe)
    # else
    #     # no custom color column
    #     mapping = nothing
    # end

    return mapping
end

function posToColor(pos)
    cx = 0.5 - pos[1]
    cy = 0.5 - pos[2]
    rx = cx * 0.7071068 + cy * 0.7071068
    ry = cx * -0.7071068 + cy * 0.7071068
    b = 1.0 - (2*sqrt(cx^2+cy^2))^2
    return RGB(0.5 - rx*1.414, 0.5 - ry*1.414, b)
end

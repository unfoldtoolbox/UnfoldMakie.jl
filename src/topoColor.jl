using AlgebraOfGraphics
using DataFrames
using AlgebraOfGraphics: to_string
using CategoricalArrays
using Colors
using ..PlotConfigs

using Makie
import Makie.plot
using Statistics
using SparseArrays
using GeometryBasics

# Work in progress
function getTopoColor(results, config)
    # for testing
    # results.position = results[:, :channel] .|> c -> ("C" * string(c))
    # show(results.position)
    
    allPositions = Point2f[]
    function customLabelPipe(position)
        push!(allPositions, Point2f(position[1], position[2]))
        return string(position)
    end

    function positionPipe(position)
        
        return (position=>posToColor(position))
    end

    function labelPipe(label)
        position = getLabelPos(label)
        push!(allPositions, Point2f(position[1], position[2]))
        return (label=>posToColor(position))
    end


    if !(config.extraData.topoPositions === nothing)
        config.mappingData = merge(config.mappingData, (;color=:customLabels))
        # create own label data column
        results.customLabels = results[:, config.extraData.topoPositions] .|> customLabelPipe
        mapping = unique(zip(results.customLabels, results[:, config.extraData.topoPositions]) .|> data -> (data[1]=>posToColor(data[2])))
    elseif !(config.extraData.topoLabel === nothing)
        config.mappingData = merge(config.mappingData, (;color=config.extraData.topoLabel))

        mapping = unique(results[:, config.extraData.topoLabel] .|> labelPipe)

    else
        # no custom color column
        mapping = nothing
    end

    return allPositions, mapping

    

end


function posToColor(pos)
    cx = 0.5 - pos[1]
    cy = 0.5 - pos[2]
    rx = cx * 0.7071068 + cy * 0.7071068
    ry = cx * -0.7071068 + cy * 0.7071068
    b = 1.0 - sqrt(2*(rx*rx+ry*ry))
    return RGB(0.5 - rx, 0.5 - ry, b)
end

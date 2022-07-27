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


# Work in progress
function getTopoColor(results, config)
    # test
    results.positions = results[:, :channel] .|> c -> (0.1*c,1/c)

    allPositions = []

    if !(config.extraData.topoPositions === nothing)
        config.mappingData.color = config.extraData.topoPositions

        mapping = unique(results[:, config.extraData.topoPositions] .|> positionPipe)

    elseif !(config.extraData.topoLabel === nothing)
        config.mappingData.color = config.extraData.topoLabel

        mapping = unique(results[:, config.extraData.topoLabel] .|> labelPipe)

    else
        show("cry")

    end

    return allPositions, mapping

    function positionPipe(position)
        push!(allPositions, position)
        return (position=>posToColor(position))
    end

    function labelPipe(label)
        position = getLabelPos(label)
        push!(allPositions, position)
        return (label=>posToColor(position))
    end

end


function posToColor(pos)
    cx = 0.5 - pos[1]
    cy = 0.5 - pos[2]
    rx = cx * 0.7071068 + cy * 0.7071068
    ry = cx * -0.7071068 + cy * 0.7071068
    b = 1.0 - sqrt(2*(rx*rx+ry*ry))
    return RGB(0.5 - rx, 0.5 - ry, b)
end

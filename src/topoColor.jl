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
function getTopoColor(results, visualData)
    visualVals = values(visualData)

    # we get the actual Positions
    # if haskey(visualVals, :positions)
    
    # # we only get the label names
    # elseif haskey(visualVals, :labels)
    # end
    
    results.labels = results.channel .|> c -> string(c)
    results.positions = results.channel .|> c -> Vec2(0.5,1/c)



    # return unique(results.positions .|> pos -> (pos=>posToColor(pos)))
    return unique(zip(results.labels, results.positions) .|> data -> (data[1]=>posToColor(data[2])))
end


function posToColor(pos)
    cx = 0.5 - pos[1]
    cy = 0.5 - pos[2]
    b = 1.0 - sqrt(2*(cx*cx+cy*cy))
    return RGB(pos[1], pos[2], b)

end
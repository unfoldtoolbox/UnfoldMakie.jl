
function getTopoPositions(;labels=nothing,positions=nothing)
    # positions have priority over labels
    if isnothing(positions) && !isnothing(labels)
        positions = getLabelPos.(labels)
    end
    @assert !isnothing(positions) "No Positions found, did you forget to provide them via positions=XX, or labels=YY?"
    return positions .|> (p -> Point2f(p[1], p[2]))
end

function getTopoColor(positions, config)
    posToColor = config.extra.topoPositionToColorFunction
#    positions = getTopoPositions(plotData,config)
    if isnothing(positions)
        return nothing
    end
    return posToColor.(positions)
    
end

function posToColorRGB(pos)
    cx = 0.5 - pos[1]
    cy = 0.5 - pos[2]
    # rotate to mimick MNE
    rx = cx * 0.7071068 + cy * 0.7071068
    ry = cx * -0.7071068 + cy * 0.7071068
    b = 1.0 - (2*sqrt(cx^2+cy^2))^2 # weight by distance
    colorwheel = RGB(0.5 - rx*1.414, 0.5 - ry*1.414, b)
    
    return colorwheel
end

function posToColorHSV(pos)
    rx = 0.5 - pos[1]
    ry = 0.5 - pos[2]
    
    b = 0.5#1.0 - (2*sqrt(cx^2+cy^2))^2
    θ,r =  cart2pol.(rx,ry)
   
    colorwheel = HSV(θ*360,b,(r./0.7)./2+0.5)

    return colorwheel
end


function posToColorRomaO(pos)
    rx = 0.5 - pos[1]
    ry = 0.5 - pos[2]

    θ,r =  cart2pol.(rx,ry)
    # circular colormap 2D
    colorwheel = get(ColorSchemes.romaO,θ)
    return colorwheel
end


function cart2pol(x,y)
θ = atan(x,y) ./(2*π)+0.5
r = sqrt(x^2 + y^2)
    return θ,r
end
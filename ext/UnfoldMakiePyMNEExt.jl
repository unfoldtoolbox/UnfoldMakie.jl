module UnfoldMakiePyMNEExt

using GeometryBasics
using PyMNE

"""
toPositions(raw::PyMNE.Py;kwargs...)

calls MNE-pythons make_eeg_layout (with optional kwargs)
Returns an array of Points
    """
function toPositions(raw::PyMNE.Py;kwargs...)
layout_from_raw = PyMNE.channels.make_eeg_layout(raw.info;kwargs...).pos
positions = pyconvert(Array,layout_from_raw)[:,1:2]

points = map(GeometryBasics.Point{2,Float64},eachrow(positions))
return points
end
end
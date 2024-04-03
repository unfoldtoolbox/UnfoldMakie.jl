module UnfoldMakiePyMNEExt

using GeometryBasics
using PyMNE
using UnfoldMakie
"""
    to_positions(raw::PyMNE.Py; kwargs...)

Calls `make_eeg_layout` from MNE-Python with optional kwargs.
**Return Value:** `Vector{Point2{Float64}`.
    """
function UnfoldMakie.to_positions(raw::PyMNE.Py; kwargs...)
    layout_from_raw = PyMNE.channels.make_eeg_layout(raw.info; kwargs...).pos
    positions = pyconvert(Array, layout_from_raw)[:, 1:2]

    points = map(GeometryBasics.Point{2,Float64}, eachrow(positions))
    return points
end
end

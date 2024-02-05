

"""
ax = RelativeAxis(figlike, p::NTuple{4, Float64}; kwargs...)

Returns an axis whose position is relative to a `GridLayout' element (via `BBox') and not relative to the scene (default behavior is Axis(..., bbox=BBox()).

`p::NTuple{4,Float64}`: Specify the position relative to the GridPosition, left:right; bottom:top, typical numbers between 0 and 1, e.g. (0.25, 0.75, 0.25, 0.75) would center an `Axis` inside this `GridPosition`.

The `kwargs...` are inserted into the axis.

f = Figure()
ax = RelativeAxis(f[1,2], (0.25, 0.75, 0.25, 0.75))	 # returns Axis centered within f[1,2]

"""
struct RelativeAxis
    layoutobservables::GridLayoutBase.LayoutObservables{GridLayout}
    relative_bbox::NTuple
end


function RelativeAxis(
    figlike::Union{GridPosition,GridSubposition,Axis},
    rel::NTuple{4,Float64};
    kwargs...)


    # it's all fake!
    layoutobservables = GridLayoutBase.LayoutObservables(
        Observable(nothing),
        Observable(nothing),
        Observable(true),
        Observable(true),
        Observable(true),
        Observable(true),
        Observable(Inside()),
        suggestedbbox=nothing)

    # generate placeholder container
    r = RelativeAxis(layoutobservables, rel)
    # lift bbox to make it relative


    bbox = lift(suggestedbbox(figlike, r), r.relative_bbox) do old, rel
        return rel_to_abs_bbox(old, rel)
    end

    # generate axis

    ax = Axis(get_figure(figlike); bbox=bbox, kwargs...)
    return ax

end
function suggestedbbox(figlike::Union{GridPosition,GridSubposition}, r::RelativeAxis)
    # asign it to GridLayout to get suggestedbbox
    figlike[] = r
    return suggestedbboxobservable(r)

end
function suggestedbbox(figlike::Axis, r::RelativeAxis)
    # need to use px_area to follow the aspect ratio of an axis
    return figlike.scene.px_area
end




get_figure(f::GridPosition) = f.layout.parent
get_figure(f::GridSubposition) = get_figure(f.parent)
get_figure(f::Axis) = f.parent


"""
    rel_to_abs_bbox(org, rel)

Takes a rectangle `org` and applies the relative transformation tuple `rel`.
Returns a `Makie.BBox`.

"""
function rel_to_abs_bbox(org, rel)
    # org => suggestedbbox of parent Grid
    # rel => BBox input between 0 / 1

    (org_left, org_right, org_bottom, org_top) = rel
    org_width = org_right - org_left
    org_heigth = org_top - org_bottom

    new_width = org.widths[1] .* org_width
    new_heigth = org.widths[2] .* org_heigth

    new_left = org.origin[1] + org.widths[1] * org_left
    new_bottom = org.origin[2] + org.widths[2] * org_bottom
    tup = new_left, new_left + new_width, new_bottom, new_bottom + new_heigth


    return BBox(tup...)
end;
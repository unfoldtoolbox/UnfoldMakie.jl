function dropnames(namedtuple::NamedTuple, names::Tuple{Vararg{Symbol}})
    keepnames = Base.diff_names(Base._nt_names(namedtuple), names)
    return NamedTuple{keepnames}(namedtuple)
end

function apply_layout_settings!(
    config::PlotConfig;
    fig = nothing,
    hm = nothing,
    drawing = nothing,
    ax = nothing,
    plot_area = (1, 1),
)
    if isnothing(ax)
        ax = current_axis()
    end

    if :hidespines ∈ keys(config.layout) && !isnothing(config.layout.hidespines)
        hidespines!(ax, config.layout.hidespines...)
    end

    if :hidedecorations ∈ keys(config.layout) && !isnothing(config.layout.hidedecorations)
        hidedecorations!(ax; config.layout.hidedecorations...)
    end
end
Makie.hidedecorations!(ax::Matrix{AxisEntries}; kwargs...) =
    Makie.hidedecorations!.(ax; kwargs...)
Makie.hidespines!(ax::Matrix{AxisEntries}, args...) = Makie.hidespines!.(ax, args...)

Makie.hidespines!(ax::AxisEntries, args...) = Makie.hidespines!.(ax.axis, args...)

"""
    default_tick_positions(values; nticks::Int=5)

Compute `nticks` evenly spaced tick positions spanning `values`.
If all values are equal, widens the range by a tiny epsilon.

**Return Value:** `Vector{Float64}` of tick positions.
"""
function default_tick_positions(values; nticks::Int = 5)
    vals = filter(isfinite, Float64.(values))
    vmin, vmax = extrema(vals)
    if vmin == vmax
        vmin -= 1e-6; vmax += 1e-6
    end
    collect(range(vmin, vmax; length = nticks))
end

"""
    _normalize_nticks(nticks)

Normalize `nticks` to `(x::Int, y::Int)`. Accepts:
- `Int` → same for both axes
- `(Int, Int)` → `(x, y)`
- `(x=Int, y=Int)` → as-is

Errors on any other shape.

**Return Value:** `NamedTuple{(:x, :y), Tuple{Int, Int}}`.
"""
function _normalize_nticks(nticks)
    if nticks isa Integer
        return (x = nticks, y = nticks)
    elseif nticks isa Tuple{<:Integer,<:Integer}
        return (x = nticks[1], y = nticks[2])
    elseif nticks isa NamedTuple
        haskey(nticks, :x) && haskey(nticks, :y) ||
            error("nticks must have keys :x and :y")
        nticks.x isa Integer || error("nticks.x must be Int")
        nticks.y isa Integer || error("nticks.y must be Int")
        return (x = nticks.x, y = nticks.y)
    else
        error("nticks must be Int, (Int,Int), or (x=Int,y=Int)")
    end
end

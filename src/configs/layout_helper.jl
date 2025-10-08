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
    default_ticks(values; nticks=5, digits=2) 

Compute evenly spaced tick positions and a simple numeric formatter.

## Arguments

- `values::AbstractVector`\\
    Numeric values used to determine the axis range.
- `nticks::Int = 5`\\
    Number of ticks to generate.
- `digits::Int = 2`\\
    Number of decimal digits to round the tick labels.

## Description

The function automatically computes a range of evenly spaced tick positions
spanning the minimum and maximum of the provided `values`.  \\
If all values are identical, a small offset (±1e-6) is applied to avoid a zero-span axis.\\
Returns both the numeric positions and a formatter function for label display.

## Return Value

Tuple `(tick_positions, tickformat)` where:
- `tick_positions` — vector of `Float64` tick locations.\\
- `tickformat` — function `xs -> string.(round.(xs; digits=digits))` producing string labels for the ticks.\\

## Example

```julia\\
ticks, fmt = default_ticks(0:100; nticks=6, digits=1)\\
fmt(ticks)
# → ["0.0", "20.0", "40.0", "60.0", "80.0", "100.0"]
"""
function default_ticks(values; nticks = 5, digits = 2)
    vals = Float64.(values)
    vmin, vmax = extrema(vals)
    # guard: avoid zero-span axis
    if vmin == vmax
        vmin -= 1e-6
        vmax += 1e-6
    end
    tick_positions = collect(range(vmin, vmax; length = nticks))
    tickformat = xs -> string.(round.(xs; digits = digits))
    return (tick_positions, tickformat)
end

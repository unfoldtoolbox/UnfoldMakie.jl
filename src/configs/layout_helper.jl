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

Compute `nticks` tick positions spanning `values` using Makie's
optimize_ticks for clean, human-readable tick placement.

**Return Value:** `Vector{Float64}` of tick positions.
"""
function default_tick_positions(values; nticks::Int = 5)
    vals = filter(isfinite, Float64.(values))
    vmin, vmax = extrema(vals)
    if vmin == vmax
        vmin -= 1e-6
        vmax += 1e-6
    end
    return Makie.PlotUtils.optimize_ticks(
        vmin,
        vmax;
        k_min = nticks - 2,
        k_max = nticks + 2,
        Q = [(1.0, 1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)],
        granularity_weight = 1.0,
        simplicity_weight = 1/6,
        coverage_weight = 1/3,
        niceness_weight = 1/4,
    )[1]
end
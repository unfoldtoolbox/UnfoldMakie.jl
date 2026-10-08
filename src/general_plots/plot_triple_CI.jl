"""
    plot_triple_CI(vec_estimate, vec_uncert; kwargs...)
    plot_triple_CI!(f::Union{GridPosition, GridLayout, Figure}, vec_estimate, vec_uncert; kwargs...)

Plot three topoplots sharing one color scale — the mean estimate and its
confidence band (mean − uncertainty and mean + uncertainty) — with a shared colorbar.

## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw into.
- `vec_estimate::AbstractVector`\\
    Per-channel mean estimate (one value per electrode).
- `vec_uncert::AbstractVector`\\
    Per-channel uncertainty (e.g. standard error), same length as `vec_estimate`.

## Keyword arguments (kwargs)
- `positions::Vector = nothing`\\
    Electrode positions. Either `positions` or `labels` must be provided.
- `labels::Vector = nothing`\\
    Electrode labels (resolved to positions). Either `positions` or `labels` must be provided.
- `uncert_label::String = "SE"`\\
    Name of the uncertainty shown in the panel labels ("Mean - SE" / "Mean + SE").
- `axis::NamedTuple = (;)`\\
    Axis options. Default: `(; backgroundcolor = :white)`.
- `visual::NamedTuple = (;)`\\
    Visual options. Default: `(; colormap = Reverse(:RdBu))`. Pass `colorrange = (lo, hi)` to override the shared range.
- `colorbar::NamedTuple = (;)`\\
    Colorbar options. Default: `(; label = "Voltage [µV]", labelsize = 24, ticklabelsize = 12, height = 240, gap = nothing)`.
- `layout::NamedTuple = (;)`\\
    Layout options. Default: `(; topo_size = 230, rowgap = -50, colgap = -90)`.

**Return Value:** `Figure` displaying the triple-CI topoplots.
"""
function plot_triple_CI(vec_estimate, vec_uncert; kwargs...)
    f = Figure()
    plot_triple_CI!(f, vec_estimate, vec_uncert; kwargs...)
    return f
end

function plot_triple_CI!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "SE",
    axis = (;),
    visual = (;),
    colorbar = (;),
    layout = (;),
)
    # defaults per config group; user kwargs override via merge
    axis = merge((; backgroundcolor = :white), axis)
    visual = merge((; colormap = Reverse(:RdBu)), visual)
    colorbar = merge(
        (; label = "Voltage [µV]", labelsize = 24, ticklabelsize = 12,
            height = 240, gap = nothing),
        colorbar,
    )
    layout = merge((; topo_size = 230, rowgap = -50, colgap = -90), layout)

    gl = f isa GridLayout ? f : (f[1, 1] = GridLayout())

    topo_axis_cfg =
        (; backgroundcolor = axis.backgroundcolor,
            width = layout.topo_size, height = layout.topo_size)
    topo_args =
        positions !== nothing ? (; positions = positions) :
        labels !== nothing ? (; labels = labels) :
        error("Either positions or labels must be provided.")

    # panels (triangular) + colorbar column
    pTopos = GridLayout()
    gl[1:2, 1:3] = pTopos
    pA = pTopos[1, 2]   # mean          (top center)
    pB = pTopos[2, 1]   # mean - uncert (bottom left)
    pC = pTopos[2, 3]   # mean + uncert (bottom right)
    pcb = gl[:, 4]

    # shared color range across all three (override via visual.colorrange)
    lower = vec_estimate .- vec_uncert
    upper = vec_estimate .+ vec_uncert
    lims =
        haskey(visual, :colorrange) ? Float32.(visual.colorrange) :
        _topo_range_from_values(vcat(vec_estimate, lower, upper))

    topo_visual = (; colorrange = lims, colormap = visual.colormap)

    _panel(pos, data, xlabel) = plot_topoplot!(
        pos, data; topo_args...,
        axis = (; backgroundcolor = axis.backgroundcolor, xlabelsize = 20, xlabel = xlabel),
        topo_axis = topo_axis_cfg,
        layout = (; use_colorbar = false),
        visual = topo_visual,
    )
    _panel(pA, vec_estimate, "")
    _panel(pB, lower, "Mean - $uncert_label")
    _panel(pC, upper, "Mean + $uncert_label")

    cb_ticks = LinRange(lims[1], lims[2], 5)
    Colorbar(
        pcb;
        colormap = visual.colormap, limits = lims,
        ticks = (cb_ticks, string.(round.(cb_ticks, digits = 2))),
        label = colorbar.label, labelsize = colorbar.labelsize,
        ticklabelsize = colorbar.ticklabelsize, height = colorbar.height,
        vertical = true, flipaxis = true, labelrotation = -π / 2,
    )

    rowgap!(pTopos, layout.rowgap)
    colgap!(pTopos, layout.colgap)
    isnothing(colorbar.gap) || colgap!(gl, 3, colorbar.gap)
    return gl
end

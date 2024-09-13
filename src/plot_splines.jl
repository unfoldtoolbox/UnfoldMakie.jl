using BSplineKit, Unfold
"""
    plot_splines(m::UnfoldModel; kwargs...)
    plot_splines!(f::Union{GridPosition, GridLayout, Figure}, m::UnfoldModel; kwargs...)

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `m::UnfoldModel`\\
    UnfoldModel with splines.

**Return Value:** `Figure` with splines and their density for basis functions.
"""
plot_splines(m::UnfoldModel; kwargs...) = plot_splines(Figure(), m; kwargs...)

function plot_splines(f::Union{GridPosition,GridLayout,Figure}, m::UnfoldModel; kwargs...)
    config = PlotConfig(:splines)
    config_kwargs!(config; kwargs...)
    ga = f[1, 1] = GridLayout()
    @debug config
    splFunction = Base.get_extension(Unfold, :UnfoldBSplineKitExt).splFunction
    spl_ix = findall(isa.(Unfold.formulas(m)[1].rhs.terms, Unfold.AbstractSplineTerm))
    spline_terms = Unfold.formulas(m)[1].rhs.terms[spl_ix[2]]

    x_range =
        range(spline_terms.breakpoints[1], stop = spline_terms.breakpoints[2], length = 100)
    basis_set = splFunction(x_range, spline_terms)

    a1 = Axis(ga[1, 1]; xlabelvisible = false, xticklabelsvisible = false)
    series!(x_range, basis_set', color = config.visual.colormap)
    f[1, 2] = Legend(ga[1, 1], a1, config.legend.title; config.legend...)

    a2 = Axis(ga[2, 1]; xautolimitmargin = (0, 0), config.axis...)
    density!(
        Unfold.events(designmatrix(m))[1][:, spline_terms.term.sym];
        color = :transparent,
        strokecolor = :black,
        strokewidth = 1,
    )
    linkxaxes!(a1, a2)
    f
end

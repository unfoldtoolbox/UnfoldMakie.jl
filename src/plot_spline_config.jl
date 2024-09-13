using BSplineKit, Unfold
"""
    plot_spline_config(m::UnfoldModel; kwargs...)

**Return Value:** `Figure` with spline configuration for basis functions.
"""
plot_spline_config(m::UnfoldModel; kwargs...) = plot_spline_config(Figure(), m; kwargs...)

function plot_spline_config(
    f::Union{GridPosition,GridLayout,Figure},
    m::UnfoldModel;
    kwargs...,
)
    splFunction = Base.get_extension(Unfold, :UnfoldBSplineKitExt).splFunction
    spl_ix = findall(isa.(Unfold.formulas(m)[1].rhs.terms, Unfold.AbstractSplineTerm))
    spline_terms = Unfold.formulas(m)[1].rhs.terms[spl_ix[2]]

    x_range =
        range(spline_terms.breakpoints[1], stop = spline_terms.breakpoints[2], length = 100)
    basis_set = splFunction(x_range, spline_terms)

    a1 = Axis(f[1, 1])
    series!(x_range, basis_set')

    a2 = Axis(f[2, 1])
    density!(
        Unfold.events(designmatrix(m))[1][:, spline_terms.term.sym];
        color = :transparent,
        strokecolor = :black,
        strokewidth = 1,
    )
    linkxaxes!(a1, a2)
    f
end

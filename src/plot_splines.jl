using BSplineKit, Unfold
"""
using Unfold: terms
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

    terms = Unfold.formulas(m)[1].rhs.terms
    spl_title = join(terms, " + ")

    splFunction = Base.get_extension(Unfold, :UnfoldBSplineKitExt).splFunction
    spl_ix = findall(isa.(terms, Unfold.AbstractSplineTerm))

    spline_terms = [terms[i] for i in spl_ix]
    j = 1
    for i in spline_terms
        x_range = range(i.breakpoints[1], stop = i.breakpoints[2], length = 100)
        basis_set = splFunction(x_range, i)
        tmp = "Spline value"
        if j > 1
            config_kwargs!(config; axis = (; ylabelvisible = false))
            tmp = ""
        end
        a1 = Axis(
            ga[1, j];
            title = string(i),
            ylabel = tmp,
            xlabelvisible = false,
            xticklabelsvisible = false,
        )
        series!(x_range, basis_set', color = config.visual.colormap)


        a2 = Axis(ga[2, j]; xautolimitmargin = (0, 0), config.axis...)
        density!(
            Unfold.events(designmatrix(m))[1][:, i.term.sym];
            color = :transparent,
            strokecolor = :black,
            strokewidth = 1,
        )
        linkxaxes!(a1, a2)
        j = j + 1
    end

    supertitle =
        Label(ga[1, 1:end, Top()], spl_title, fontsize = 20, padding = (0, 0, 40, 0))

    f
end

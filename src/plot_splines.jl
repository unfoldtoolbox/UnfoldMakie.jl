using BSplineKit, Unfold

"""
    plot_splines(m::UnfoldModel; kwargs...)
    plot_splines!(f::Union{GridPosition, GridLayout, Figure}, m::UnfoldModel; kwargs...)

Visualization of spline terms in an UnfoldModel. Two subplots are generated for each spline term:\\
1) the basis function of the spline; 2) the density of the underlying covariate.\\

Multiple spline terms are arranged across columns.\\
Dashed lines indicate spline knots.

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `m::UnfoldModel`\\
    UnfoldModel with splines.
- `spline_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of spline subplots.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:spline_default))    
- `density_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of density subplots.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:density_default))
- `superlabel_config::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the Label on the top of the plot.\\
    To see all options just type `?Label` in REPL.\\
    Defaults: $(supportive_defaults(:superlabel_default))

$(_docstring(:splines))

**Return Value:** `Figure` with splines and their density for basis functions.
"""
plot_splines(m::UnfoldModel; kwargs...) = plot_splines(Figure(), m; kwargs...)

function plot_splines(
    f::Union{GridPosition,GridLayout,Figure},
    m::UnfoldModel;
    spline_axis = (;),
    density_axis = (;),
    superlabel_config = (;),
    kwargs...,
)
    config = PlotConfig(:splines)
    config_kwargs!(config; kwargs...)
    spline_axis, density_axis, superlabel_config =
        supportive_axes_management(spline_axis, density_axis, superlabel_config)

    ga = f[1, 1] = GridLayout()

    terms = Unfold.formulas(m)[1].rhs.terms
    spl_title = join(terms, " + ")

    splFunction = Base.get_extension(Unfold, :UnfoldBSplineKitExt).splFunction
    spl_ix = findall(isa.(terms, Unfold.AbstractSplineTerm))
    @assert !isempty(spl_ix) "No spline term is found in UnfoldModel. Does your UnfoldModel really have a `spl(...)` or other `AbstractSplineTerm`?"

    spline_terms = [terms[i] for i in spl_ix]
    subplot_id = 1
    for spline_term in spline_terms
        x_range = range(
            spline_term.breakpoints[1],
            stop = spline_term.breakpoints[end],
            length = 100,
        )
        basis_set = splFunction(x_range, spline_term)

        if subplot_id > 1
            spline_axis = update_axis(spline_axis; ylabelvisible = false)
            density_axis = update_axis(density_axis; ylabelvisible = false)
        end
        a1 = Axis(ga[1, subplot_id]; title = string(spline_term), spline_axis...)
        series!(
            x_range,
            basis_set',
            color = resample_cmap(config.visual.colormap, size(basis_set')[1]),
        ) # continuous color map used
        vlines!(
            spline_term.breakpoints;
            ymin = extrema(basis_set')[1],
            ymax = extrema(basis_set')[2],
            linestyle = :dash,
        )
        a2 = Axis(ga[2, subplot_id]; xlabel = string(spline_term.term.sym), density_axis...)
        density!(
            Unfold.events(designmatrix(m))[1][:, spline_term.term.sym];
            color = :transparent,
            strokecolor = :black,
            strokewidth = 1,
        )
        linkxaxes!(a1, a2)
        subplot_id = subplot_id + 1
    end
    Label(ga[1, 1:end, Top()], spl_title; superlabel_config...)
    f
end

function supportive_axes_management(spline_axis, density_axis, superlabel_config)
    spline_axis = update_axis(supportive_defaults(:spline_default); spline_axis...)
    density_axis = update_axis(supportive_defaults(:density_default); density_axis...)
    superlabel_config =
        update_axis(supportive_defaults(:superlabel_default); superlabel_config...)
    return spline_axis, density_axis, superlabel_config
end

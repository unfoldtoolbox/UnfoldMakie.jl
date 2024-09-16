using BSplineKit, Unfold
"""
    plot_splines(m::UnfoldModel; kwargs...)
    plot_splines!(f::Union{GridPosition, GridLayout, Figure}, m::UnfoldModel; kwargs...)

Shows two subfigures. First, baseses of splines. Second, density of splines.\\
Dashed lines shows spline knots.

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
    subplot_id = 1
    for spline_term in spline_terms
        #basises = BSplineBasis(BSplineOrder(i.order), i.breakpoints)
        #knots = BSplineKit.knots(basises)
        x_range = range(
            spline_term.breakpoints[1],
            stop = spline_term.breakpoints[end],
            length = 100,
        )
        basis_set = splFunction(x_range, spline_term)

        ylabel_first = "Spline value"
        if subplot_id > 1
            config_kwargs!(config; axis = (; ylabelvisible = false))
            ylabel_first = ""
        end
        a1 = Axis(
            ga[1, subplot_id];
            title = string(spline_term),
            ylabel = ylabel_first,
            xlabelvisible = false,
            xticklabelsvisible = false,
        )
        series!(
            x_range,
            basis_set',
            color = resample_cmap(config.visual.colormap, size(basis_set')[1]),
        ) #contionus colormap used
        vlines!(
            spline_term.breakpoints;
            ymin = extrema(basis_set')[1],
            ymax = extrema(basis_set')[2],
            linestyle = :dash,
        )
        #scatter!(spline_term.breakpoints, [0,0,0,0,0,0,0,0]; markersize = 10, strokecolor = :tomato, strokewidth = 3)

        a2 = Axis(ga[2, subplot_id]; xautolimitmargin = (0, 0), config.axis...)
        density!(
            Unfold.events(designmatrix(m))[1][:, spline_term.term.sym];
            color = :transparent,
            strokecolor = :black,
            strokewidth = 1,
        )
        linkxaxes!(a1, a2)
        subplot_id = subplot_id + 1
    end

    supertitle =
        Label(ga[1, 1:end, Top()], spl_title, fontsize = 20, padding = (0, 0, 40, 0))
    f
end

#=   crange = [1, 2] # default
    if isnothing(color)
        color = 1
    elseif isa(color, AbstractVector)
        if isa(color[1], String)
            # categorical colors
            un_c = unique(color)
            color_ix = [findfirst(un_c .== c) for c in color]
            #@assert length(un_c) == 1 "Only single color found, please don't specify color, "
            if length(un_c) == 1
                @warn "Only single unique value found in the specified color vector"
                color = cgrad(config.visual.colormap, 2)[color_ix]
            else
                color = cgrad(config.visual.colormap, length(un_c))[color_ix]
            end
            #crange = [1,length(unique(color))]
        else
            # continuous color
            crange = [minimum(color), maximum(color)]
        end
    end
 =#

"""
    plot_erpimage!(f::Union{GridPosition, GridLayout, Figure}, data::Matrix{Float64}; kwargs...)
    plot_erpimage(data::Matrix{Float64}; kwargs...)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, Vector{Float32}}`\\
    Data for the plot visualization.
        
## Keyword argumets (kwargs) 
- `erpblur::Number = 10`\\
    Number indicating how much blur is applied to the image. \\
    Gaussian blur of the `ImageFiltering` module is used.\\
    Non-Positive values deactivate the blur.
- `sortvalues::Vector{Int64} = false`\\
    Parameter over which plot will be sorted. Using `sortperm()` of Base Julia.\\ 
    `sortperm()` computes a permutation of the array's indices that puts the array in sorted order. 
- `sortindex::Vector{Int64} = nothing`\\
    Sorting over index values.
- `meanplot::bool = false`\\
    Add a line plot below the ERP image, showing the mean of the data.
- `show_sortval::bool = false`\\
    Add a plot below the ERP image, showing the distribution of the sorting data.
- `sortval_xlabel::String = "Sorting value"`\\
    If `show_sortval = true` controls xlabel.
- `axis.ylabel::String = "Trials"`\\
    If `sortvalues = true` the default text will change to "Sorted trials", but it could be changed to any values specified manually.

$(_docstring(:erpimage))

**Return Value:** `Figure` displaying the ERP image. 
"""
plot_erpimage(data; kwargs...) = plot_erpimage!(Figure(), data; kwargs...) # no times + no figure?

# no times?
plot_erpimage!(f::Union{GridPosition,GridLayout,Figure}, data::AbstractMatrix; kwargs...) =
    plot_erpimage!(f, Observable(data); kwargs...)

plot_erpimage!(f::Union{GridPosition,GridLayout,Figure}, args...; kwargs...) =
    plot_erpimage!(f, map(_as_observable, args)...; kwargs...)

plot_erpimage!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Observable{<:AbstractMatrix};
    kwargs...,
) = plot_erpimage!(f, @lift(1:size($data, 1)), data; kwargs...)

# argument list has no figure? Add one!
plot_erpimage(
    times::AbstractVector,
    data::Union{<:Observable{Matrix{<:Real}},Matrix{<:Real}};
    kwargs...,
) = plot_erpimage!(Figure(), times, data; kwargs...)

_as_observable(x) = Observable(x)
_as_observable(x::Observable) = x

function plot_erpimage!(
    f::Union{GridPosition,GridLayout,Figure},
    times::Observable{<:AbstractVector},
    data::Observable{<:AbstractMatrix{<:Real}};
    sortvalues = Observable(nothing),
    sortindex = Observable(nothing),
    erpblur = Observable(10),
    meanplot = false,
    show_sortval = false,
    sortval_xlabel = Observable("Sorting value"),
    kwargs..., # not observables for a while ;)
)

    sortvalues = _as_observable(sortvalues)
    sortindex = _as_observable(sortindex)
    erpblur = _as_observable(erpblur)

    config = PlotConfig(:erpimage)
    if isnothing(sortindex) && !isnothing(sortvalues)
        config_kwargs!(config; axis = (; ylabel = "Trials sorted"))
    end
    config_kwargs!(
        config;
        layout = (; show_legend = false, use_colorbar = false),
        kwargs...,
    )

    !isnothing(to_value(sortindex)) ? @assert(to_value(sortindex) isa Vector{Int}) : ""
    ax = Axis(f[1:4, 1:4]; config.axis...)

    ax.yticks = [
        1,
        size(to_value(data), 2) ÷ 4,
        size(to_value(data), 2) ÷ 2,
        size(to_value(data), 2) - (size(to_value(data), 2) ÷ 4),
        size(to_value(data), 2),
    ]
    ax.yticklabelsvisible = true
    if isnothing(to_value(sortindex))
        if isnothing(to_value(sortvalues))
            sortindex = @lift(1:size($data, 2))
        else
            if length(to_value(sortvalues)) != size(to_value(data), 2)
                error(
                    "The length of sortvalues differs from the length of data trials. This leads to incorrect sorting.",
                )
            else
                sortindex = @lift(sortperm($sortvalues))
            end
        end
    end
    filtered_data = @lift(
        UnfoldMakie.imfilter(
            $data[:, $sortindex],
            UnfoldMakie.Kernel.gaussian((0, max($erpblur, 0))),
        )
    )

    yvals = @lift(1:size($filtered_data, 2))
    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    if meanplot
        ei_meanplot(ax, data, config, f, times, show_sortval)
    end

    if show_sortval
        ei_sortvalue(sortvalues, f, ax, hm, config, sortval_xlabel)
    else
        Colorbar(
            f[1:4, 5],
            hm,
            label = config.colorbar.label,
            labelrotation = config.colorbar.labelrotation,
        )
    end

    apply_layout_settings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))
    return f

end

function ei_meanplot(ax, data, config, f, times, show_sortval)
    ax.xlabelvisible = false #padding of the main plot
    ax.xticklabelsvisible = false

    trace = @lift(mean($data, dims = 2)[:, 1])
    axbottom = Axis(
        f[5, 1:4];
        ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label,
        xlabel = "Time [s]",
        xlabelpadding = 0,
        xautolimitmargin = (0, 0),
        limits = @lift((
            minimum($times),
            maximum($times),
            minimum($trace),
            maximum($trace),
        )),
    )

    lines!(axbottom, times, trace)
    apply_layout_settings!(config; fig = f, ax = axbottom)
    linkxaxes!(ax, axbottom)
    if show_sortval
        rowgap!(f.layout, -30)
    end
end

function ei_sortvalue(sortvalues, f, ax, hm, config, sortval_xlabel)
    if isnothing(to_value(sortvalues))
        error("`show_sortval` needs non-empty `sortvalues` argument")
    end
    if all(isnan, to_value(sortvalues))
        error("`show_sortval` can not take `sortvalues` with all NaN-values")
    end
    axleft = Axis(
        f[1:4, 5];
        title = sortval_xlabel,
        ylabelvisible = false,
        yticklabelsvisible = false,
        xautolimitmargin = (0, 0),
        yautolimitmargin = (0, 0),
        xticks = @lift([
            round(minimum($sortvalues), digits = 2),
            round(maximum($sortvalues), digits = 2),
        ]),
        limits = @lift((
            minimum($sortvalues),
            maximum($sortvalues),
            1,
            size($sortvalues, 1),
        )),
    )
    xs = @lift(1:1:size($sortvalues, 1))
    ys = @lift(sort($sortvalues)[:, 1])

    lines!(axleft, ys, xs)
    Colorbar(
        f[1:4, 6],
        hm,
        label = config.colorbar.label,
        labelrotation = config.colorbar.labelrotation,
    )
    apply_layout_settings!(config; fig = f, ax = axleft)
    linkyaxes!(ax, axleft)

end

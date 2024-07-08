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
    Add a plot on the right from ERP image, showing the distribution of the sorting data.
- `sortval_xlabel::String = "Sorting variable"`\\
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
    sortval_xlabel = Observable("Sorting variable"),
    kwargs..., # not observables for a while ;)
)
    ga = f[1, 1:2] = GridLayout()
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
    ax = Axis(ga[1:4, 1:4]; config.axis...)

    ax.yticks = [
        1,
        size(to_value(data), 2) ÷ 4,
        size(to_value(data), 2) ÷ 2,
        size(to_value(data), 2) - (size(to_value(data), 2) ÷ 4),
        size(to_value(data), 2),
    ]
    ax.yticklabelsvisible = true
    sortindex = sortindex_managment(sortindex, sortvalues, data)
    filtered_data = @lift(
        UnfoldMakie.imfilter(
            $data[:, $sortindex],
            UnfoldMakie.Kernel.gaussian((0, max($erpblur, 0))),
        )
    )

    yvals = @lift(1:size($filtered_data, 2))

    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    if meanplot
        ei_meanplot(ax, data, config, f, ga, times, show_sortval)
    end

    if show_sortval
        ei_sortvalue(sortvalues, f, ax, hm, config, sortval_xlabel)
    else
        Colorbar(
            ga[1:4, 5],
            hm,
            label = config.colorbar.label,
            labelrotation = config.colorbar.labelrotation,
        )
    end
    hidespines!(ax, :r, :t)
    apply_layout_settings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))
    return f
end

function ei_meanplot(ax, data, config, f, ga, times, show_sortval)
    ax.xlabelvisible = false #padding of the main plot
    ax.xticklabelsvisible = false

    trace = @lift(mean($data, dims = 2)[:, 1])
    axbottom = Axis(
        ga[5, 1:4];
        height = 100,
        ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label,
        xlabel = "Time [s]",
        xlabelpadding = 0,
        xautolimitmargin = (0, 0),
        limits = @lift((
            minimum($times),
            maximum($times),
            minimum($trace) - 0.5,
            maximum($trace) + 0.5,
        )),
    )
    rowgap!(ga, 7)
    hidespines!(axbottom, :r, :t)
    lines!(axbottom, times, trace)
    apply_layout_settings!(config; fig = f, ax = axbottom)
end

function ei_sortvalue(sortvalues, f, ax, hm, config, sortval_xlabel)
    if isnothing(to_value(sortvalues))
        error("`show_sortval` needs non-empty `sortvalues` argument")
    end
    if all(isnan, to_value(sortvalues))
        error("`show_sortval` can not take `sortvalues` with all NaN-values")
    end
    gb = f[1, 3] = GridLayout()
    axleft = Axis(
        gb[1:4, 1:5];
        xlabel = sortval_xlabel,
        ylabelvisible = true,
        yticklabelsvisible = false,
        #xautolimitmargin = (-1, 1),
        #yautolimitmargin = (1, 100),
        xticks = @lift([
            round(minimum($sortvalues), digits = 2),
            round(maximum($sortvalues), digits = 2),
        ]),
        limits = @lift((
            minimum($sortvalues) - (maximum($sortvalues) / 100 * 3),
            maximum($sortvalues) + (maximum($sortvalues) / 100 * 3),
            0 - (length($sortvalues) / 100 * 3),
            length($sortvalues) + (length($sortvalues) / 100 * 3), #they should be realtive
        )),
    )
    ys = @lift(1:length($sortvalues))
    xs = @lift(sort($sortvalues))
    axempty = Axis(gb[5, 1])
    hidedecorations!(axempty)
    hidespines!(axempty)
    hidespines!(axleft, :r, :t)
    #scatter!(axleft, xs, ys)
    lines!(axleft, xs, ys)
    Colorbar(
        gb[1:4, 6],
        hm,
        label = config.colorbar.label,
        labelrotation = config.colorbar.labelrotation,
    )
    apply_layout_settings!(config; fig = f, ax = axleft)
end

function sortindex_managment(sortindex, sortvalues, data)
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
    return sortindex
end

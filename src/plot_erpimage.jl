"""
    plot_erpimage!(f::Union{GridPosition, GridLayout, Figure}, data::AbstractMatrix{Float64}; kwargs...)
    plot_erpimage!(f::Union{GridPosition, GridLayout, Figure}, data::Observable{<:AbstractMatrix}; kwargs...)
    plot_erpimage!(f::Union{GridPosition, GridLayout, Figure}, times::Observable{<:AbstractVector}, data::Observable{<:AbstractMatrix{<:Real}}; kwargs...)

    plot_erpimage(times::AbstractVector, data::Union{<:Observable{Matrix{<:Real}}, Matrix{<:Real}}; kwargs...)
    plot_erpimage(data::Matrix{Float64}; kwargs...)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, Vector{Float32}}`\\
    Data for the plot visualization.
         
## Keyword arguments (kwargs) 
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
- `meanplot_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of meanplot.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:meanplot_default))
- `sortplot_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of meanplot.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:sortplot_default))

$(_docstring(:erpimage))

**Return Value:** `Figure` displaying the ERP image. 
"""
plot_erpimage(data; kwargs...) = plot_erpimage!(Figure(), data; kwargs...)

plot_erpimage(
    times::AbstractVector,
    data::Union{<:Observable{Matrix{<:Real}},AbstractMatrix{<:Real}};
    kwargs...,
) = plot_erpimage!(Figure(), times, data; kwargs...)


plot_erpimage!(f::Union{GridPosition,GridLayout,Figure}, args...; kwargs...) =
    plot_erpimage!(f, map(_as_observable, args)...; kwargs...)

plot_erpimage!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Observable{<:AbstractMatrix};
    kwargs...,
) = plot_erpimage!(f, @lift(1:size($data, 1)), data; kwargs...)

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
    meanplot_axis = (;),
    sortplot_axis = (;),
    kwargs...,
)
    ga = f[1, 1:2] = GridLayout()
    sortvalues = _as_observable(sortvalues)
    sortindex = _as_observable(sortindex)
    erpblur = _as_observable(erpblur)

    config = PlotConfig(:erpimage)
    if isnothing(sortindex) && !isnothing(sortvalues)
        config_kwargs!(config; axis = (; ylabel = "Trials sorted"))
    end

    config_kwargs!(config; kwargs...)
    !isnothing(to_value(sortindex)) ? @assert(to_value(sortindex) isa Vector{Int}) : ""
    ax = Axis(ga[1:4, 1:4]; config.axis...)

    ax.yticks = LinRange(1, size(to_value(data), 2), 5)

    ax.yticklabelsvisible = true
    sortindex = sortindex_management(sortindex, sortvalues, data)
    filtered_data = @lift(
        UnfoldMakie.imfilter(
            $data[:, $sortindex],
            UnfoldMakie.Kernel.gaussian((0, max($erpblur, 0))),
        )
    )

    yvals = @lift(1:size($filtered_data, 2))

    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    if meanplot
        ei_meanplot(ax, data, config, f, ga, times, meanplot_axis)
    end

    if show_sortval
        ei_sortvalue(sortvalues, f, ax, hm, config, sortval_xlabel, sortplot_axis)
    elseif config.layout.use_colorbar != false
        Colorbar(
            ga[1:4, 5],
            hm,
            label = config.colorbar.label,
            labelrotation = config.colorbar.labelrotation,
        )
    end
    hidespines!(ax, :r, :t)
    apply_layout_settings!(config; fig = f, hm = hm, ax = ax, plot_area = (4, 1))
    return f
end

function ei_meanplot(ax, data, config, f, ga, times, meanplot_axis)
    ax.xlabelvisible = false #padding of the main plot
    ax.xticklabelsvisible = false

    trace = @lift(mean($data, dims = 2)[:, 1])
    meanplot_axis = update_axis(supportive_defaults(:meanplot_default); meanplot_axis...)
    xticks = @lift(round.(LinRange(minimum($times), maximum($times), 5), digits = 2))
    yticks = @lift(round.(LinRange(minimum($trace), maximum($trace), 5), digits = 1))

    axbottom = Axis(
        ga[5, 1:4];
        ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label,
        xticks = xticks,
        yticks = yticks,
        limits = @lift((
            minimum($times),
            maximum($times),
            minimum($trace) - 0.5,
            maximum($trace) + 0.5,
        )),
        meanplot_axis...,
    )
    rowgap!(ga, 7)
    hidespines!(axbottom, :r, :t)
    lines!(axbottom, times, trace)
    apply_layout_settings!(config; fig = f, ax = axbottom)
end

function ei_sortvalue(sortvalues, f, ax, hm, config, sortval_xlabel, sortplot_axis)
    if isnothing(to_value(sortvalues))
        error("`show_sortval` needs non-empty `sortvalues` argument")
    end

    gb = f[1, 3] = GridLayout()
    sortplot_axis = update_axis(supportive_defaults(:sortplot_default); sortplot_axis...)
    ys = @lift(1:length($sortvalues))
    xs = @lift(sort($sortvalues))
    if !isa(sortvalues, Observable{Vector{String}})
        if all(isnan, to_value(sortvalues))
            error("`show_sortval` can not take `sortvalues` with all NaN-values")
        end
        axleft = Axis(
            gb[1:4, 1:5];
            xlabel = sortval_xlabel,
            xticks = @lift(
                round.(LinRange(minimum($sortvalues), maximum($sortvalues), 2), digits = 2)
            ),
            limits = @lift((
                minimum($sortvalues) - (maximum($sortvalues) / 100 * 3),
                maximum($sortvalues) + (maximum($sortvalues) / 100 * 3),
                0 - (length($sortvalues) / 100 * 3),
                length($sortvalues) + (length($sortvalues) / 100 * 3), #they should be realtive
            )),
            sortplot_axis...,
        )
        lines!(axleft, xs, ys)
    else
        axleft = Axis(gb[1:4, 1:5]; xlabel = sortval_xlabel, sortplot_axis...)
        stairs!(axleft, ys, ys)
    end

    axempty = Axis(gb[5, 1])
    hidedecorations!(axempty)
    hidespines!(axempty)
    hidespines!(axleft, :r, :t)
    if config.layout.use_colorbar != false
        Colorbar(
            gb[1:4, 6],
            hm,
            label = config.colorbar.label,
            labelrotation = config.colorbar.labelrotation,
        )
    end
    apply_layout_settings!(config; fig = f, ax = axleft)
end

function sortindex_management(sortindex, sortvalues, data)
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

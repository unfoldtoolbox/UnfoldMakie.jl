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
plot_erpimage(times::AbstractVector, data::Matrix{<:Real}; kwargs...) =
    plot_erpimage!(Figure(), times, data; kwargs...)



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
        size(to_value(data), 2) ÷ 3,
        size(to_value(data), 2) ÷ 3 * 2,
        size(to_value(data), 2),
    ]
    if isnothing(to_value(sortindex))
        if isnothing(to_value(sortvalues))
            sortindex = @lift(1:size($data, 2))
        else
            sortindex = @lift(sortperm($sortvalues))
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
        ax.xlabelvisible = false
        ax.xticklabelsvisible = false

        sub_config1 = deepcopy(config)
        config_kwargs!(
            sub_config1;
            layout = (; show_legend = false),
            axis = (;
                ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label
            ),
        )
        axbottom = Axis(
            f[5, 1:4];
            xlabelpadding = 0,
            xautolimitmargin = (0, 0),
            sub_config1.axis...,
        )
        #axbottom.xticks = (minimum(to_value(times)), 0.0, maximum(to_value(times)) ÷ 3, maximum(to_value(times)) ÷ 3 * 2, maximum(to_value(times)))

        lines!(axbottom, times, @lift(mean($data, dims = 2)[:, 1]))
        apply_layout_settings!(sub_config1; fig = f, ax = axbottom)
        linkxaxes!(ax, axbottom)
        if show_sortval
            rowgap!(f.layout, -30)
        end
    end
    if show_sortval
        if isnothing(to_value(sortvalues))
            error("`show_sortval` needs `sortvalues` argument")
        end
        sub_config2 = deepcopy(config)
        config_kwargs!(
            sub_config2;
            layout = (; show_legend = false, use_colorbar = false),
            axis = (; ylabel = "Trials sorted", xlabel = "Sorting value"),
        )
        axleft = Axis(
            f[1:4, 5];
            ylabelvisible = false,
            yticklabelsvisible = false,
            xautolimitmargin = (0, 0),
            yautolimitmargin = (0, 0),
            sub_config2.axis...,
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
        axleft.xticks = [
            minimum(to_value(sortvalues)),
            maximum(to_value(sortvalues)) ÷ 3,
            maximum(to_value(sortvalues)) ÷ 3 * 2,
            maximum(to_value(sortvalues)),
        ]
        apply_layout_settings!(sub_config2; fig = f, ax = axleft)
        linkyaxes!(ax, axleft)
    else
        Colorbar(
            f[1:4, 5],
            hm,
            label = config.colorbar.label,
            labelrotation = config.colorbar.labelrotation,
        )
    end

    ylims!(ax, low = 0) # how to solve high value??
    apply_layout_settings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))
    return f

end

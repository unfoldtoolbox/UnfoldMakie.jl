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
plot_erpimage(plot::Matrix{<:Real}; kwargs...) = plot_erpimage!(Figure(), plot; kwargs...) # no times + no figure?

# no times?
plot_erpimage!(f::Union{GridPosition,GridLayout,Figure}, plot::Matrix{<:Real}; kwargs...) =
    plot_erpimage!(f, 1:size(plot, 1), plot; kwargs...)

# no figure?
plot_erpimage(times::AbstractVector, plot::Matrix{<:Real}; kwargs...) =
    plot_erpimage!(Figure(), times, plot; kwargs...)

function plot_erpimage!(
    f::Union{GridPosition,GridLayout,Figure},
    times::AbstractVector,
    plot::Matrix{<:Real};
    sortvalues = nothing,
    sortindex = nothing,
    meanplot = false,
    erpblur = 10,
    show_sortval = false,
    kwargs...,
)

    config = PlotConfig(:erpimage)
    if isnothing(sortindex) && !isnothing(sortvalues)
        config_kwargs!(config; axis = (; ylabel = "Trials sorted"))
    end
    config_kwargs!(config; kwargs...)

    !isnothing(sortindex) ? @assert(sortindex isa Vector{Int}) : ""
    ax = Axis(f[1:4, 1]; config.axis...)

    if isnothing(sortindex)
        if isnothing(sortvalues)
            sortindex = 1:size(plot, 2)
        else
            sortindex = sortperm(sortvalues)
        end
    end

    filtered_data = UnfoldMakie.imfilter(
        plot[:, sortindex],
        UnfoldMakie.Kernel.gaussian((0, max(erpblur, 0))),
    )

    yvals = 1:size(filtered_data, 2)
    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    UnfoldMakie.apply_layout_settings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))


    if meanplot
        ax.xlabelvisible = false
        ax.xticklabelsvisible = false
        subConfig1 = deepcopy(config)
        config_kwargs!(
            subConfig1;
            layout = (; show_legend = false),
            axis = (;
                ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label
            ),
        )
        axright = Axis(f[5, 1]; xlabelpadding = 0, subConfig1.axis...)
        lines!(axright, times, mean(plot, dims = 2)[:, 1])
        apply_layout_settings!(subConfig1; fig = f, ax = axright)
        linkxaxes!(ax, axright)
        rowgap!(f.layout, -30)
    end
    if show_sortval
        if isnothing(sortvalues)
            error("`show_sortval` needs `sortvalues` argument")
        end
        subConfig2 = deepcopy(config)
        config_kwargs!(
            subConfig2;
            layout = (; show_legend = false),
            axis = (; ylabel = "Trials sorted", xlabel = "Sorting value"),
        )
        axleft =
            Axis(f[1:4, 3]; yaxisposition = :right, flip_ylabel = true, subConfig2.axis...)
        # @show size(sort(sortvalues))
        xs = 1:1:size(sortvalues, 1)
        ys = sort(sortvalues)[:, 1]
        lines!(axleft, ys, xs)
        apply_layout_settings!(subConfig2; fig = f, ax = axleft)
        ylims!(axleft, low = 0)
        xlims!(axleft, low = 0)

    end
    ylims!(ax, low = 0) # how to solve high value??
    #println(ax.finallimits)
    return f

end

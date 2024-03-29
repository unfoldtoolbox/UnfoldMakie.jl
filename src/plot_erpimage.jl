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
    Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.
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
    if !isnothing(sortvalues)
        yvals = [minimum(sortvalues), maximum(sortvalues)]
    end

    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    UnfoldMakie.apply_layout_settings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))

    if meanplot
        # UserInput
        subConfig = deepcopy(config)
        config_kwargs!(
            subConfig;
            layout = (; show_legend = false),
            axis = (;
                ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label
            ),
        )

        axisOffset =
            (config.layout.show_legend && config.layout.legend_position == :bottom) ? 1 : 0
        subAxis = Axis(f[5+axisOffset, 1]; subConfig.axis...)

        lines!(subAxis, mean(plot, dims = 2)[:, 1])
        apply_layout_settings!(subConfig; fig = f, ax = subAxis)
    end

    return f

end

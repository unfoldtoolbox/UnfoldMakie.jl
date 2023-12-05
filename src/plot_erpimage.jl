"""
    plot_erpimage!(f::Union{GridPosition, GridLayout, Figure}, data::Matrix{Float64}; kwargs...)
    plot_erpimage(data::Matrix{Float64}; kwargs...)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plot::Matrix{Float64}`: Data for the plot visualization
        
## Keyword Arguments
- `erpblur` (Number, `10`): number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module.
Non-Positive values deactivate the blur.
- `sortix` (default: `nothing`): .
- `sortvalues` (bool, `false`): parameter over which plot will be sorted. Using sortperm() of Base Julia. 
    - sortperm() computes a permutation of the array's indices that puts the array into sorted order. 
- `meanplot` (bool, `false`): Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.

$(_docstring(:erpimage))

## Return Value:
The input `f`
"""

# no times + no figure?
plot_erpimage(plot::Matrix{<:Real}; kwargs...) = plot_erpimage!(Figure(), plot; kwargs...)

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
    sortix = nothing,
    meanplot = false,
    erpblur = 10,
    kwargs...,
)
    config = PlotConfig(:erpimage)
    UnfoldMakie.config_kwargs!(config; kwargs...)


    !isnothing(sortix) ? @assert(sortix isa Vector{Int}) : ""
    ax = Axis(f[1:4, 1]; config.axis...)
    if isnothing(sortix)
        if isnothing(sortvalues)
            sortix = 1:size(plot, 2)
        else
            sortix = sortperm(sortvalues)

        end
    end

    filtered_data = UnfoldMakie.imfilter(
        plot[:, sortix],
        UnfoldMakie.Kernel.gaussian((0, max(erpblur, 0))),
    )

    yvals = 1:size(filtered_data, 2)
    if !isnothing(sortvalues)
        yvals = [minimum(sortvalues), maximum(sortvalues)]
    end

    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    UnfoldMakie.applyLayoutSettings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))

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
        applyLayoutSettings!(subConfig; fig = f, ax = subAxis)
    end

    return f

end

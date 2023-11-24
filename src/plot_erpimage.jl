


"""
    plot_erpimage!(f::Union{GridPosition, GridLayout, Figure}, data::Matrix{Float64}; kwargs...)
    plot_erpimage(data::Matrix{Float64}; kwargs...)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::Matrix{Float64}`: Data for the plot visualization
        
## Keyword Arguments
`erpBlur` (Number, `10`) - Number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module.
Non-Positive values deactivate the blur.

`sortvalues` (bool, `false`) - parameter over which plot will be sorted. Using sortperm() of Base Julia 
(sortperm() computes a permutation of the array's indices that puts the array into sorted order). 

`meanPlot`: (bool, `false`) - Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.

$(_docstring(:erpimage))

## Return Value:
The input `f`
"""

# no times + no figure?
plot_erpimage(plotData::Matrix{<:Real}; kwargs...) =
    plot_erpimage!(Figure(), plotData; kwargs...)

# no times?
plot_erpimage!(f::Union{GridPosition,GridLayout,Figure}, plotData::Matrix{<:Real}; kwargs...) =
    plot_erpimage!(f, 1:size(plotData, 1), plotData; kwargs...)


# no figure?
plot_erpimage(times::AbstractVector, plotData::Matrix{<:Real}; kwargs...) =
    plot_erpimage!(Figure(), times, plotData; kwargs...)

function plot_erpimage!(
    f::Union{GridPosition,GridLayout,Figure},
    times::AbstractVector,
    plotData::Matrix{<:Real};
    sortvalues = nothing,
    sortix = nothing,
    meanPlot = false,
    erpBlur = 10,
    kwargs...,
)
    config = PlotConfig(:erpimage)
    UnfoldMakie.config_kwargs!(config; kwargs...)


    !isnothing(sortix) ? @assert(sortix isa Vector{Int}) : ""
    ax = Axis(f[1:4, 1]; config.axis...)
    if isnothing(sortix)
        if isnothing(sortvalues)
            sortix = 1:size(plotData, 2)
        else
            sortix = sortperm(sortvalues)

        end
    end

    filtered_data = UnfoldMakie.imfilter(
        plotData[:, sortix],
        UnfoldMakie.Kernel.gaussian((0, max(erpBlur, 0))),
    )

    yvals = 1:size(filtered_data, 2)
    if !isnothing(sortvalues)
        yvals = [minimum(sortvalues), maximum(sortvalues)]
    end

    hm = heatmap!(ax, times, yvals, filtered_data; config.visual...)

    UnfoldMakie.applyLayoutSettings!(config; fig = f, hm = hm, ax = ax, plotArea = (4, 1))

    if meanPlot
        # UserInput
        subConfig = deepcopy(config)
        config_kwargs!(
            subConfig;
            layout = (; showLegend = false),
            axis = (;
                ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label
            ),
        )

        axisOffset =
            (config.layout.showLegend && config.layout.legendPosition == :bottom) ? 1 : 0
        subAxis = Axis(f[5+axisOffset, 1]; subConfig.axis...)

        lines!(subAxis, mean(plotData, dims = 2)[:, 1])
        applyLayoutSettings!(subConfig; fig = f, ax = subAxis)
    end

    return f

end

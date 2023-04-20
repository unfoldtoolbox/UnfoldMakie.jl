


"""
    function plot_erpimage!(f::Union{GridPosition, Figure}, data::Matrix{Float64};kwargs...)
    function plot_erpimage(data::Matrix{Float64};kwargs...)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::Matrix{Float64}`: Data for the plot visualization
        
## Extra Data Behavior (...;extra=(;[key]=value)):
`erpBlur` (Number, `10`) - Number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module.
Non-Positive values deactivate the blur.

`sortData` (bool, `false`) - Indicating whether the data is sorted; using sortperm() of Base Julia 
(sortperm() computes a permutation of the array's indices that puts the array into sorted order). 

`meanPlot`: (bool, `false`) - Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.

## Return Value:
The input `f`
"""

plot_erpimage(plotData::Matrix{<:Real};kwargs...) = plot_erpimage!(Figure(),plotData;kwargs...)
function plot_erpimage!(f::Union{GridPosition, Figure}, plotData::Matrix{<:Real};kwargs...)
    config = PlotConfig(:erpimage)
    config_kwargs!(config;kwargs...)

    ax = Axis(f[1:4,1]; config.axis...)

    filtered_data = imfilter(plotData, Kernel.gaussian((0,max(config.extra.erpBlur,0))))
    
    if config.extra.sortData
        ix = sortperm([a[1] for a in argmax(plotData, dims=1)][1,:])   # ix - trials sorted by time of maximum spike
        hm = heatmap!(ax,(filtered_data[:,ix]); config.visual...)
    else
        hm = heatmap!(ax,(filtered_data[:,:]); config.visual...)
    end

    applyLayoutSettings(config; fig = f, hm = hm, ax = ax, plotArea = (4,1))

    if config.extra.meanPlot
        # UserInput
        subConfig = deepcopy(config)
        config_kwargs!(subConfig;layout=(;
            showLegend = false,
        ),
        axis=(;
            ylabel = config.colorbar.label === nothing ? "" : config.colorbar.label))

        
            #limits = (config.axis.limits[1], config.axis.limits[2], nothing, nothing)))
        
        axisOffset = (config.layout.showLegend && config.layout.legendPosition == :bottom) ? 1 : 0
        subAxis = Axis(f[5+axisOffset,1]; subConfig.axis...)

        lines!(subAxis,mean(plotData,dims=2)[:,1])
        applyLayoutSettings(subConfig; fig = f, ax=subAxis)
    end

    return f

end
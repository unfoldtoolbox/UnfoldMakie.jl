using ImageFiltering


plot_erp(plotData::DataFrame;kwargs...) = plot_line(plotData, PlotConfig(:erp);kwargs...)
plot_erp!(f::Union{GridPosition, Figure},plotData::DataFrame;kwargs...) = plot_line!(f,plotData, PlotConfig(:erp);kwargs...)


plot_erp(plotData::Matrix{Real},config::PlotConfig) =  plot_erp!(Figure(), plotData, config)
plot_erp(plotData::Matrix{Real};kwargs...) = plot_erp(plotData,PlotConfig(:erp);kwargs...)

"""
    function plot_erp!(f::Union{GridPosition, Figure}, data::Matrix{Float64},config::PlotConfig)

Plot an ERP image.
## Arguments:
- `f::Union{GridPosition, Figure}`: Figure or GridPosition that the plot should be drawn into
- `plotData::Matrix{Float64}`: Data for the plot visualization.
- `config::PlotConfig`: Instance of PlotConfig being applied to the visualization.
        
## Extra Data Behavior:
`erpBlur`:

Default : `10`

Number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module.
Non-Positive values deactivate the blur.

`sortData`:

Default: `false`

Indicating whether the data is sorted; using sortperm() of Base Julia 
(sortperm() computes a permutation of the array's indices that puts the array into sorted order). 

`meanPlot`:

Default : `false`

Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.

## Return Value:
The input `f`
"""
function plot_erp!(f::Union{GridPosition, Figure}, plotData::Matrix{Float64},config::PlotConfig)
    ax = Axis(f[1:4,1]; config.axisData...)

    filtered_data = imfilter(plotData, Kernel.gaussian((0,max(config.extraData.erpBlur,0))))
    
    if config.extraData.sortData
        ix = sortperm([a[1] for a in argmax(plotData, dims=1)][1,:])   # ix - trials sorted by time of maximum spike
        hm = heatmap!(ax,(filtered_data[:,ix]); config.visualData...)
    else
        hm = heatmap!(ax,(filtered_data[:,:]); config.visualData...)
    end

    applyLayoutSettings(config; fig = f, hm = hm, ax = ax, plotArea = (4,1))

    if config.extraData.meanPlot
        # UserInput
        subConfig = deepcopy(config)
        subConfig.setLayoutValues!(
            showLegend = false,
        )
        subConfig.setAxisValues!(
            ylabel = config.colorbarData.label === nothing ? "" : config.colorbarData.label
        )
        if :limits ∈ keys(subConfig.axisData)
            subConfig.setAxisValues!(limits = (config.axisData.limits[1], config.axisData.limits[2], nothing, nothing))
        end
        if !(:rightspinevisible ∈ keys(subConfig.axisData))
            subConfig.setAxisValues!(rightspinevisible = false)
        end
        if !(:topspinevisible ∈ keys(subConfig.axisData))
            subConfig.setAxisValues!(topspinevisible = false)
        end

        axisOffset = (config.layoutData.showLegend && config.layoutData.legendPosition == :bottom) ? 1 : 0
        subAxis = Axis(f[5+axisOffset,1]; subConfig.axisData...)

        lines!(subAxis,mean(plotData,dims=2)[:,1])
        applyLayoutSettings(subConfig; fig = f, ax=subAxis)
    end

    return f

end
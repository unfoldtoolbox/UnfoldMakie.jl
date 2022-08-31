using ImageFiltering

"""
    function plot_erp(data::Matrix{Float64},config::PlotConfig)

Plot an ERP image.
## Arguments:
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
A figure displaying the ERP image.
"""
function plot_erp(plotData::Matrix{Float64},config::PlotConfig)
    return plot_erp!(Figure(), plotData, config)
end

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

    filtered_data = imfilter(plotData, Kernel.gaussian((0,config.extraData.erpBlur)))
    
    if config.extraData.sortData
        ix = sortperm([a[1] for a in argmax(plotData, dims=1)][1,:])   # ix - trials sorted by time of maximum spike
        hm = heatmap!(ax,(filtered_data[:,ix]); config.visualData...)
    else
        hm = heatmap!(ax,(filtered_data[:,:]); config.visualData...)
    end

    applyLayoutSettings(config; fig = f, hm = hm, ax = ax, plotArea = (4,1))

    if config.extraData.meanPlot
        # UserInput
        axisOffset = (config.layoutData.showLegend && config.layoutData.legendPosition == :bottom) ? 1 : 0
        lines(f[5+axisOffset,1],mean(plotData,dims=2)[:,1])
        config2 = deepcopy(config)
        config2.setLayoutValues(
            showLegend = false,
            ylabel = config.colorbarData.label === nothing ? "" : config.colorbarData.label,
            ylims = nothing
        )
        applyLayoutSettings(config2; fig = f)
    end

    return f

end
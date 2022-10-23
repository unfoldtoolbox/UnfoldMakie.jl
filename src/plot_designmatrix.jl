using Statistics
using SparseArrays


""" 
    function plot_designmatrix(plotData::Unfold.DesignMatrix,[config::PlotConfig];kwargs...)
        

Plot a designmatrix. 
## Arguments:
- `plotData::Unfold.DesignMatrix`: Data for the plot visualization.
- `config::PlotConfig`: (optional) Instance of PlotConfig being applied to the visualization.

## Extra Data Behavior (...;setExtraValues=(;[key]=value))
`standardizeData`:

Default : `true`

Indicating whether the data is standardized by pointwise division of the data with its sampled standard deviation.

`sortData`:

Default : `true`

Indicating whether the data is sorted; using sortslices() of Base Julia. 

`xTicks`:

Default : `nothing`

Indicating the number of labels on the x-axis.
Behavior if specified in configuration:
- xTicks = 0: no labels are placed.
- xTicks = 1: first possible label is placed.
- xTicks = 2: first and last possible labels are placed.
- 2 < xTicks < `number of labels`: Equally distribute the labels.
- xTicks ≥ `number of labels`: all labels are placed.

## Return Value:
A figure displaying the designmatrix. 
"""
plot_designmatrix(plotData::Unfold.DesignMatrix,config::PlotConfig;kwargs...) = plot_designmatrix!(Figure(), plotData, config;kwargs...)
plot_designmatrix(plotData::Unfold.DesignMatrix;kwargs...) = plot_designmatrix(plotData,PlotConfig(:design);kwargs...)
function plot_designmatrix!(f::Union{GridPosition, Figure}, plotData::Unfold.DesignMatrix,config::PlotConfig;kwargs...)

    config_kwargs!(config;kwargs...)
    designmat = Unfold.get_Xs(plotData);
    if config.extraData.standardizeData
        designmat = designmat ./ std(designmat,dims=1)
        designmat[isinf.(designmat)] .= 1.
    end

    if isa(designmat, SparseMatrixCSC)
        if config.extraData.sortData
            @warn "Sorting does not make sense for timeexpanded designmatrices. sortData has been set to `false`"
            
            config.setExtraValues!(sortData=false)
        end
        designmat = Matrix(designmat[end÷2-2000:end÷2+2000,:])
    end

    if config.extraData.sortData
        designmat = Base.sortslices(designmat,dims=1)
    end
    labels = Unfold.get_coefnames(plotData)
    
    lLength = length(labels)
    # only change xTicks if we want less then all
    if (config.extraData.xTicks !== nothing && config.extraData.xTicks < lLength)
        @assert(config.extraData.xTicks >= 0,"xTicks shouldn't be negative")
        # sections between xTicks
        sectionSize = (lLength-2)/(config.extraData.xTicks-1)
        newLabels = []

        # first tick. Empty if 0 ticks
        if config.extraData.xTicks >= 1
            push!(newLabels, labels[1])
        else
            push!(newLabels, "")   
        end

        # fill in ticks in the middle
        for i in 1:(lLength-2)
            # checks if we're at the end of a section, but NO tick on the very last section
            if i % sectionSize < 1 && i < ((config.extraData.xTicks-1) * sectionSize)
                push!(newLabels, labels[i+1])
            else
                push!(newLabels, "")
            end
        end
        
        # last tick at the end
        if config.extraData.xTicks >= 2
            push!(newLabels, labels[lLength-1])
        else
            push!(newLabels, "")
        end

        labels = newLabels
    end
    

    # plot Designmatrix
    config.setAxisValues!(xticks=(1:length(labels),labels))
    ax = Axis(f[1, 1]; config.axisData...)
    hm = heatmap!(ax, designmat'; config.visualData...)
    
    if isa(designmat, SparseMatrixCSC)
        ax.yreversed = true
    end
    
    applyLayoutSettings(config; fig = f, hm = hm)

    return f
end
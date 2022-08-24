using Statistics
using SparseArrays


""" 
    plot_design(plotData::Unfold.DesignMatrix,config::PlotConfig;standardize=true,sort=false)

Plot a designmatrix. 
## Arguments:
- `plotData::Unfold.DesignMatrix`: data for the designmatrix being visualized.
- `config::PlotConfig`: data of the configuration being applied to the visualization.
- `standardize=true`: boolean indicating, whether the designmatrix should be standardized.
Default is true. Standardization is performed by elementwise division of the designmatrix 
with the sample standard deviation of the designmatrix.
- `sort=false`: boolean indicating, whether the designmatrix should be sorted.
Default is false. Sorting is performed with `Base.sortslices`.

## Behavior:
### `config.extraData.xTicks`:
Indicating the number of labels on the x-axis.
Behavior if specified in configuration:
- xTicks = 0: no labels are placed.
- xTicks = 1: first possible label is placed.
- xTicks = 2: first and last possible labels are placed.
- 2 < xTicks < number of labels: xTicks-2 labels are placed 
between the first and last.
- xTicks ≥ number of labels: all labels are placed.
### ? `config.visualData.axis`: 
TODO: wait for config completion!
### `config.extraData.showLegend`:
Indicating whether a colorbar of the Makie module should be shown as a legend.
### TODO: more?

## Return Value:
The figure corresponding to the first heatmap return of the Makie module. 
A colorbar is included as a legend if set in the configuration 
(config.extraData.showLegend = true).
"""
function plot_design(plotData::Unfold.DesignMatrix,config::PlotConfig)
    return plot_design!(Figure(), plotData, config)
end

function plot_design!(f::Union{GridPosition, Figure}, plotData::Unfold.DesignMatrix,config::PlotConfig)
    designmat = Unfold.get_Xs(plotData);
    if config.extraData.standardizeData
        designmat = designmat ./ std(designmat,dims=1)
        designmat[isinf.(designmat)] .= 1.
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
    
    # @show labels
    if isa(designmat, SparseMatrixCSC)
        @assert(!config.extraData.sortData,"Sorting does not make sense for timeexpanded designmatrices")
        designmat = Matrix(designmat[end÷2-2000:end÷2+2000,:])
    end
    # plot Designmatrix
    ax = Axis(f[1, 1], xticklabelrotation=pi/8, xticks=(1:length(labels),labels))
    hm = heatmap!(ax, designmat'; config.visualData...)
    
    if isa(designmat, SparseMatrixCSC)
        ax.yreversed = true
    end

    applyLayoutSettings(config; fig = f, hm = hm)

    return f
end
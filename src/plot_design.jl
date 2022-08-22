using Statistics
using SparseArrays


""" Plot design matrix  """
function plot_design(X::Unfold.DesignMatrix,config::PlotConfig;standardize=true,sort=false)
    designmat = Unfold.get_Xs(X);
    if standardize
        designmat = designmat ./ std(designmat,dims=1)
        designmat[isinf.(designmat)] .= 1.
    end
    if sort
        designmat = Base.sortslices(designmat,dims=1)
    end
    labels = Unfold.get_coefnames(X)
    
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
        @assert(!sort,"Sorting does not make sense for timeexpanded designmatrices")
        designmat = Matrix(designmat[end÷2-2000:end÷2+2000,:])
    end
    # plot Designmatrix
    axisSettings =  merge(config.visualData.axis, (;xticks=(1:length(labels),labels)))
    fig, ax, hm = heatmap(designmat',axis=axisSettings)
    
    if isa(designmat, SparseMatrixCSC)
        ax.yreversed = true
    end

    applyLayoutSettings(config; fig = fig, hm = hm)

    return fig
end




""" Legacy  """
function plot(X::Unfold.DesignMatrix;standardize=true,sort=false)
    designmat = Unfold.get_Xs(X);
    if standardize
        designmat = designmat ./ std(designmat,dims=1)
        designmat[isinf.(designmat)] .= 1.
    end
    if sort
        designmat = Base.sortslices(designmat,dims=1)
    end
    labels = Unfold.get_coefnames(X)

    if isa(designmat, SparseMatrixCSC)
        @assert(!sort,"Sorting does not make sense for timeexpanded designmatrices")
        designmat = Matrix(designmat[end÷2-2000:end÷2+2000,:])
    end
    # plot Designmatrix
    fig, ax, hm = heatmap(designmat',axis=(xticks=(1:length(labels),labels),xticklabelrotation = pi/8),)
    Colorbar(fig[1,2],hm)
    
    if isa(designmat, SparseMatrixCSC)
        ax.yreversed = true
    end
    return fig
end
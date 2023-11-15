""" 
    plot_designmatrix!(f::Union{GridPosition, GridLayout, Figure}, data::Unfold.DesignMatrix; kwargs...)
    plot_designmatrix(data::Unfold.DesignMatrix; kwargs...)
        

Plot a designmatrix. 
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`: Figure or GridPosition (e.g. f[2, 3]) in which the plot will be placed into. A new axis is created.
- `data::Unfold.DesignMatrix`: data for the plot visualization.

## kwargs
- `standardize_data` (bool,`true`): indicates whether the data is standardized by pointwise division of the data with its sampled standard deviation.
- `sort_data` (bool, `true`): indicates whether the data is sorted; using sortslices() of Base Julia. 
- `xticks` (`nothing`): returns the number of labels on the x-axis. Behavior is set in the configuration:
    - xticks = 0: no labels are placed.
    - xticks = 1: first possible label is placed.
    - xticks = 2: first and last possible labels are placed.
    - 2 < xticks < `number of labels`: equally distribute the labels.
    - xticks ≥ `number of labels`: all labels are placed.

$(_docstring(:designmat))

## Return Value:
A figure displaying the designmatrix. 
"""
plot_designmatrix(data::Unfold.DesignMatrix; kwargs...) =
    plot_designmatrix!(Figure(), data; kwargs...)
function plot_designmatrix!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Unfold.DesignMatrix;
    xticks = nothing,
    sort_data = false,
    standardize_data = false,
    kwargs...,
)
    config = PlotConfig(:designmat)
    config_kwargs!(config; kwargs...)
    designmat = Unfold.get_Xs(data)
    if standardize_data
        designmat = designmat ./ std(designmat, dims = 1)
        designmat[isinf.(designmat)] .= 1.0
    end

    if isa(designmat, SparseMatrixCSC)
        if sort_data
            @warn "Sorting does not make sense for time-expanded designmatrices. sort_data has been set to `false`"

           sort_data = false
        end
        designmat = Matrix(designmat[end÷2-2000:end÷2+2000, :])
    end

    if sort_data
        designmat = Base.sortslices(designmat, dims = 1)
    end
    labels = Unfold.get_coefnames(data)

    lLength = length(labels)
    # only change xticks if we want less then all
    if (xticks !== nothing && xticks < lLength)
        @assert(xticks >= 0, "xticks shouldn't be negative")
        # sections between xticks
        sectionSize = (lLength - 2) / (xticks - 1)
        newLabels = []

        # first tick. Empty if 0 ticks
        if xticks >= 1
            push!(newLabels, labels[1])
        else
            push!(newLabels, "")
        end

        # fill in ticks in the middle
        for i = 1:(lLength-2)
            # checks if we're at the end of a section, but NO tick on the very last section
            if i % sectionSize < 1 && i < ((xticks - 1) * sectionSize)
                push!(newLabels, labels[i+1])
            else
                push!(newLabels, "")
            end
        end

        # last tick at the end
        if xticks >= 2
            push!(newLabels, labels[lLength-1])
        else
            push!(newLabels, "")
        end

        labels = newLabels
    end


    # plot Designmatrix
    config.axis = merge(config.axis, (; xticks = (1:length(labels), labels)))
    ax = Axis(f[1, 1]; config.axis...)
    hm = heatmap!(ax, designmat'; config.visual...)

    if isa(designmat, SparseMatrixCSC)
        ax.yreversed = true
    end

    applyLayoutSettings!(config; fig = f, hm = hm)

    return f
end

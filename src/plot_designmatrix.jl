""" 
    plot_designmatrix!(f::Union{GridPosition, GridLayout, Figure}, data::Unfold.DesignMatrix; kwargs...)
    plot_designmatrix(data::Unfold.DesignMatrix; kwargs...)
        
Plot a designmatrix. 
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Unfold.DesignMatrix`\\
    Data for the plot visualization.
## Keyword arguments (kwargs)
- `standardize_data::Bool = true`\\
    Indicates whether the data is standardized by pointwise division of the data with its sampled standard deviation.
- `sort_data::Bool = true`\\
    Indicates whether the data is sorted. It uses `sortslices()` of Base Julia. 
- `xticks::Num = nothing`\\
    Returns the number of labels on the x axis.
    - `xticks` = 0: no labels are placed.
    - `xticks` = 1: first possible label is placed.
    - `xticks` = 2: first and last possible labels are placed.
    - 2 < `xticks` < `number of labels`: equally distribute the labels.
    - `xticks` ≥ `number of labels`: all labels are placed.
$(_docstring(:designmat))
**Return Value:** `Figure` displaying the Design matrix. 
"""
plot_designmatrix(
    data::Union{<:Vector{<:AbstractDesignMatrix},<:AbstractDesignMatrix};
    kwargs...,
) = plot_designmatrix!(Figure(), data; kwargs...)

function plot_designmatrix!(f, data::Vector{<:AbstractDesignMatrix}; kwargs...)
    if length(data) > 1
        @warn "multiple $(length(data)) designmatrices found, plotting the first one"
    end
    plot_designmatrix!(f, data[1]; kwargs...)
end
function plot_designmatrix!(
    f::Union{GridPosition,GridLayout,Figure},
    data::AbstractDesignMatrix;
    xticks = nothing,
    sort_data = false,
    standardize_data = false,
    kwargs...,
)
    config = PlotConfig(:designmat)
    config_kwargs!(config; kwargs...)
    designmat = modelmatrix(data)
    if standardize_data
        designmat = designmat ./ std(designmat, dims = 1)
        designmat[isinf.(designmat)] .= 1.0
    end

    if isa(designmat, SparseMatrixCSC)
        if sort_data
            @warn "Sorting does not make sense for time-expanded designmatrices. sort_data has been set to `false`"
            sort_data = false
        end
        designmat = Matrix(designmat[end÷2-2000:end÷2+2000, :]) # needs a size(designmat) of at least 4000 x Any
    end

    if sort_data
        designmat = Base.sortslices(designmat, dims = 1)
    end
    labels0 = replace.(Unfold.get_coefnames(data), r"\s*:" => ":")

    if length(split(labels0[1], ": ")) > 1
        labels = map(x -> join(split(x, ": ")[3]), labels0)
        labels_top1 = Unfold.extract_coef_info(Unfold.get_coefnames(data), 2)
        unique_names = String[]
        labels_top2 = String[""]
        for el in labels_top1
            if !in(el, unique_names)
                push!(unique_names, el)
                push!(labels_top2, el)
            else
                push!(labels_top2, "")
            end
        end
    end
    lLength = length(labels0)
    # only change xticks if we want less then all
    if (xticks !== nothing && xticks < lLength)
        @assert(xticks >= 0, "xticks shouldn't be negative")
        # sections between xticks
        section_size = (lLength - 2) / (xticks - 1)
        new_labels = []

        # first tick. Empty if 0 ticks
        if xticks >= 1
            push!(new_labels, labels0[1])
        else
            push!(new_labels, "")
        end

        # fill in ticks in the middle
        for i = 1:(lLength-2)
            # checks if we're at the end of a section, but NO tick on the very last section
            if i % section_size < 1 && i < ((xticks - 1) * section_size)
                push!(new_labels, labels0[i+1])
            else
                push!(new_labels, "")
            end
        end

        # last tick at the end
        if xticks >= 2
            push!(new_labels, labels0[lLength-1])
        else
            push!(new_labels, "")
        end

        labels0 = new_labels
    end
    if length(split(labels0[1], ": ")) > 1
        ax2 = Axis(
            f[1, 1],
            xticklabelcolor = :red,
            xaxisposition = :top;
            xticks = (1:length(labels_top2), labels_top2),
        )
        hidespines!(ax2)
        hidexdecorations!(ax2, ticklabels = false, ticks = false)
        hm = heatmap!(ax2, designmat'; config.visual...)
    else
        labels = labels0
    end

    # plot Designmatrix
    config.axis = merge(config.axis, (; xticks = (1:length(labels), labels)))
    ax = Axis(f[1, 1]; config.axis...)
    hm = heatmap!(ax, designmat'; config.visual...)

    if isa(designmat, SparseMatrixCSC)
        ax.yreversed = true
    end

    apply_layout_settings!(config; fig = f, hm = hm)

    return f
end
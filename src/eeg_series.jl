"""
    eeg_matrix_to_dataframe(data::Matrix, label)

Helper function converting a matrix (channel x times) to a tidy `DataFrame` with columns `:estimate`, `:time` and `:label`.

**Return Value:** `DataFrame`.
"""
function eeg_matrix_to_dataframe(data, label)
    df = DataFrame(data', label)
    df[!, :time] .= 1:nrow(df)
    df = stack(df, Not([:time]); variable_name = :label, value_name = "estimate")
    return df
end

"""
    eeg_topoplot_series(data::DataFrame,
        f,
        data::DataFrame;
        bin_width,
        bin_num,
        y = :erp,
        label = :label,
        col = :time,
        row = nothing,
        col_labels = false,
        row_labels = false,
        rasterize_heatmaps = true,
        combinefun = mean,
        xlim_topo,
        ylim_topo,
        topoplot_attributes...,
    )
    eeg_topoplot_series!(fig, data::DataFrame, bin_width; kwargs..)

Plot a series of topoplots. 
The function automatically takes the `combinefun = mean` over the `:time` column of `data` in `bin_width` steps.
- `f` \\
    Figure object. \\
- `data::DataFrame`\\
    Needs the columns `:time` and `y(=:erp)`, and `label(=:label)`. \\
    If `data` is a matrix, it is automatically cast to a dataframe, time bins are in samples, labels are `string.(1:size(data,1))`.
- `bin_width = :time` \\
    In `:time` units, specifying the time steps. All other keyword arguments are passed to the `EEG_TopoPlot` recipe. \\
    In most cases, the user should specify the electrode positions with `positions = pos`.
- `col`, `row = :time` \\
    Specify the field to be divided into columns and rows. The default is `col=:time` to split by the time field and `row = nothing`. \\
    Useful to split by a condition, e.g. `...(..., col=:time, row=:condition)` would result in multiple (as many as different values in `df.condition`) rows of topoplot series.
- `row_labels`, `col_labels = false` \\
    Indicate whether there should be labels in the plots in the first column to indicate the row value and in the last row to indicate the time (typically timerange).
    
# Example

```julia-repl
df = DataFrame(:erp => repeat(1:63, 100), :time => repeat(1:20, 5 * 63), :label => repeat(1:63, 100)) # simulated data
pos = [(1:63) ./ 63 .* (sin.(range(-2 * pi, 2 * pi, 63))) (1:63) ./ 63 .* cos.(range(-2 * pi, 2 * pi, 63))] .* 0.5 .+ 0.5 # simulated electrode positions
pos = [Point2.(pos[k, 1], pos[k, 2]) for k in 1:size(pos, 1)]
eeg_topoplot_series(df, 5; positions = pos)
```

**Return Value:** `Tuple{Figure, Vector{Any}}`.
"""
function eeg_topoplot_series(
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix};
    figure = NamedTuple(),
    kwargs...,
)
    return eeg_topoplot_series!(Figure(; figure...), data; kwargs...)
end
# allow to specify bin_width as an keyword for nicer readability

#eeg_topoplot_series(data::Union{<:Observable,<:DataFrame,<:AbstractMatrix}; kwargs...) =
#    eeg_topoplot_series(data; kwargs...)
# AbstractMatrix
function eeg_topoplot_series!(
    fig,
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix};
    kwargs...,
)
    return eeg_topoplot_series!(fig, data, string.(1:size(data, 1)); kwargs...)
end

# convert a 2D Matrix to the dataframe
function eeg_topoplot_series(
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix},
    labels;
    kwargs...,
)
    return eeg_topoplot_series(eeg_matrix_to_dataframe(data, labels); kwargs...)
end
function eeg_topoplot_series!(
    fig,
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix},
    labels;
    kwargs...,
)
    return eeg_topoplot_series!(fig, eeg_matrix_to_dataframe(data, labels); kwargs...)
end

function eeg_topoplot_series!(
    fig,
    data_mean::Union{<:Observable{<:DataFrame},<:DataFrame};
    #bin_width = nothing,
    #bin_num = nothing,
    y = :erp,
    label = :label,
    col = :time,
    row = nothing,
    col_labels = false,
    row_labels = false,
    rasterize_heatmaps = true,
    #combinefun = mean,
    xlim_topo = (-0.25, 1.25),
    ylim_topo = (-0.25, 1.25),
    interactive_scatter = nothing,
    highlight_scatter = false,
    topoplot_attributes...,
)
    axis_options = create_axis_options(xlim_topo, ylim_topo)
    # aggregate the data over time bins
    # using same colormap + contour levels for all plots

    (q_min, q_max) = extract_colorrange(to_value(data_mean), y)
    topoplot_attributes = merge(
        (
            colorrange = (q_min, q_max),
            interp_resolution = (128, 128),
            contours = (levels = range(q_min, q_max; length = 7)),
        ),
        topoplot_attributes,
    )

    # do the col/row plot
    select_col = isnothing(col) ? 1 : unique(to_value(data_mean)[:, col])
    select_row = isnothing(row) ? 1 : unique(to_value(data_mean)[:, row])

    if interactive_scatter != nothing
        @assert isa(interactive_scatter, Observable)
    end

    axlist = []
    for r = 1:length(select_row)
        for c = 1:length(select_col)
            ax = single_topoplot(
                fig,
                r,
                c,
                row,
                col,
                select_row,
                select_col,
                y,
                label,
                axis_options,
                data_mean,
                highlight_scatter,
                interactive_scatter,
                topoplot_attributes,
                col_labels,
                row_labels,
                rasterize_heatmaps,
            )
            push!(axlist, ax)

        end
    end
    if typeof(fig) != GridLayout && typeof(fig) != GridLayoutBase.GridSubposition
        colgap!(fig.layout, 0)
    end
    return fig, axlist
end

function single_topoplot(
    fig,
    r,
    c,
    row,
    col,
    select_row,
    select_col,
    y,
    label,
    axis_options,
    data_mean,
    highlight_scatter,
    interactive_scatter,
    topoplot_attributes,
    col_labels,
    row_labels,
    rasterize_heatmaps,
)
    ax = Axis(fig[:, :][r, c]; axis_options...)
    # select one topoplot
    sel = 1 .== ones(size(to_value(data_mean), 1)) # select all
    if !isnothing(col)
        sel = sel .&& (to_value(data_mean)[:, col] .== select_col[c]) # subselect
    end
    if !isnothing(row)
        sel = sel .&& (to_value(data_mean)[:, row] .== select_row[r]) # subselect
    end
    df_single = @lift($data_mean[sel, :])

    # select labels
    labels = to_value(df_single)[:, label]
    # select data
    d_vec = @lift($df_single[:, y])
    # plot it
    if highlight_scatter != false || interactive_scatter != nothing
        strokecolor = Observable(repeat([:black], length(to_value(d_vec))))
        highlight_feature = (; strokecolor = strokecolor)

        if :label_scatter ∈ keys(topoplot_attributes)
            topoplot_attributes = merge(
                topoplot_attributes,
                (;
                    label_scatter = if isa(topoplot_attributes[:label_scatter], NamedTuple)
                        merge(topoplot_attributes[:label_scatter], highlight_feature)
                    else
                        highlight_feature
                    end
                ),
            )
        else
            topoplot_attributes =
                merge(topoplot_attributes, (; label_scatter = highlight_feature))
        end
    end
    if isempty(to_value(d_vec))
        return
    end
    single_topoplot = eeg_topoplot!(ax, d_vec, labels; topoplot_attributes...)
    if rasterize_heatmaps
        single_topoplot.plots[1].plots[1].rasterize = true
    end

    # to put column and row labels
    if col_labels == true
        if r == length(select_row) && col_labels
            ax.xlabel = string(to_value(df_single)[1, col])
            ax.xlabelvisible = true
        end
        if c == 1 && length(select_row) > 1 && row_labels
            ax.ylabel = string(to_value(df_single)[1, row])
            ax.ylabelvisible = true
        end
    else
        ax.xlabelvisible = true
        ax.xlabel = string(to_value(df_single).time[1, :][])
    end
    interctive_toposeries(interactive_scatter, single_topoplot)
    return ax
end

function interctive_toposeries(interactive_scatter, single_topoplot)
    if interactive_scatter != false
        on(events(single_topoplot).mousebutton) do event
            if event.button == Mouse.left && event.action == Mouse.press
                plt, p = pick(single_topoplot)
                if isa(plt, Makie.Scatter) && plt == single_topoplot.plots[1].plots[3]
                    plt.strokecolor[] .= :black
                    plt.strokecolor[][p] = :white
                    notify(plt.strokecolor) # not sure why this is necessary, but oh well..
                    interactive_scatter[] = (r, c, p)
                end
            end
        end
    end
end

function create_axis_options(xlim_topo, ylim_topo)
    return (
        aspect = 1,
        xgridvisible = false,
        xminorgridvisible = false,
        xminorticksvisible = false,
        xticksvisible = false,
        xticklabelsvisible = false,
        xlabelvisible = false,
        ygridvisible = false,
        yminorgridvisible = false,
        yminorticksvisible = false,
        yticksvisible = false,
        yticklabelsvisible = false,
        ylabelvisible = false,
        leftspinevisible = false,
        rightspinevisible = false,
        topspinevisible = false,
        bottomspinevisible = false,
        xpanlock = true,
        ypanlock = true,
        xzoomlock = true,
        yzoomlock = true,
        xrectzoom = false,
        yrectzoom = false,
        limits = (xlim_topo, ylim_topo),
    )
end

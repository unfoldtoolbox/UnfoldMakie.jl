"""
    eeg_matrix_to_dataframe(data::Matrix, label)

Helper function converting a matrix (channel x times) to a tidy `DataFrame` with columns `:estimate`, `:time` and `:label`.

**Return Value:** `DataFrame`.
"""
eeg_matrix_to_dataframe(data::Matrix) =
    eeg_matrix_to_dataframe(data, string.(1:size(data, 1)))

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
The function takes the `combinefun = mean` over the `:time` column of `data` in `bin_width` steps.
- `f` \\
    Figure object. \\
- `data::DataFrame`\\
    Needs the columns `:time` and `y(=:erp)`, and `label(=:label)`. \\
    If `data` is a matrix, it is automatically cast to a dataframe, time bins are in samples, labels are `string.(1:size(data,1))`.
- `col`, `row = :time` \\
    Specify the field to be divided into columns and rows. The default is `col = :time` to split by the time field and `row = nothing`. \\
    Useful to split by a condition, e.g. `...(..., col = :time, row = :condition)` would result in multiple (as many as different values in `df.condition`) rows of topoplot series.
- `row_labels`, `col_labels = false` \\
    Indicate whether there should be labels in the plots in the first column to indicate the row value and in the last row to indicate the time (typically timerange).
- `combinefun::Function = mean`\\
    Specify how the samples within `bin_width` are summarised.\\
    Example functions: `mean`, `median`, `std`.  

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
    data::Union{<:Observable{<:DataFrame},<:DataFrame};
    cat_or_cont_columns = "cont",
    y = :erp,
    label = :label,
    col = :time,
    row = nothing,
    col_labels = false,
    row_labels = false,
    rasterize_heatmaps = true,
    combinefun = mean,
    topoplot_axes = (;),
    interactive_scatter = nothing,
    highlight_scatter = false,
    topoplot_attributes...,
)
    axis_options = create_axis_options()
    axis_options = merge(axis_options, topoplot_axes)

    # aggregate the data over time bins
    # using same colormap + contour levels for all plots
    data = _as_observable(data)
    select_col = isnothing(col) ? 1 : unique(to_value(data)[:, :col_coord])
    select_row = isnothing(row) ? 1 : unique(to_value(data)[:, :row_coord])
    if eltype(to_value(data)[!, col]) <: Number
        data_mean = @lift(
            df_grouping(
                $data;
                col_y = y,
                fun = combinefun,
                grouping = [label, :col_coord, :row_coord],
            )
        )
    else
        # categorical detected, no binning necessary
        data_mean = data
    end
    (q_min, q_max) = extract_colorrange(to_value(data_mean), y)
    topoplot_attributes = merge(
        (
            colorrange = (q_min, q_max),
            interp_resolution = (128, 128),
            #contours = (; levels = range(q_min, q_max; length = 7)),
        ),
        topoplot_attributes,
    )
    # do the col/row plot
    axlist = []
    for r = 1:length(select_row)
        for c = 1:length(select_col)
            ax = Axis(fig[:, :][r, c]; axis_options...)
            df_single =
                topoplot_subselection(data_mean, col, row, select_col, select_row, r, c)
            # select labels
            labels = to_value(df_single)[:, label]
            # select data
            single_y = @lift($df_single[:, y])
            scatter_management(
                single_y,
                topoplot_attributes,
                highlight_scatter,
                interactive_scatter,
            )
            if isempty(to_value(single_y))
                break
            end
            single_topoplot = eeg_topoplot!(ax, single_y, labels; topoplot_attributes...)
            if rasterize_heatmaps
                single_topoplot.plots[1].plots[1].rasterize = true
            end
            label_management(ax, cat_or_cont_columns, df_single, col) # to put column and row labels
            interactive_toposeries(interactive_scatter, single_topoplot)
            push!(axlist, ax)
        end
    end
    if typeof(fig) != GridLayout && typeof(fig) != GridLayoutBase.GridSubposition
        colgap!(fig.layout, 0)
    end
    return fig, axlist, topoplot_attributes[:colorrange]
end

function label_management(ax, cat_or_cont_columns, df_single, col)
    if cat_or_cont_columns == "cat"
        ax.xlabel = string(to_value(df_single)[1, col])
    else
        ax.xlabel = string(to_value(df_single).cont_cuts[1, :][])
    end
end

function topoplot_subselection(data_mean, col, row, select_col, select_row, r, c)
    sel = 1 .== ones(size(to_value(data_mean), 1))
    if !isnothing(col)
        sel = sel .&& (to_value(data_mean)[:, :col_coord] .== select_col[c]) # subselect
    end
    if !isnothing(row)
        sel = sel .&& (to_value(data_mean)[:, :row_coord] .== select_row[r]) # subselect
    end
    df_single = @lift($data_mean[sel, :])
    return df_single
end

function scatter_management(
    single_y,
    topoplot_attributes,
    highlight_scatter,
    interactive_scatter,
)
    if highlight_scatter != false || interactive_scatter != nothing
        strokecolor = Observable(repeat([:black], length(to_value(single_y))))
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
end

function interactive_toposeries(interactive_scatter, single_topoplot)
    if interactive_scatter != nothing
        @assert isa(interactive_scatter, Observable)
    end
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

function create_axis_options()
    return (
        aspect = 1,
        title = "",
        xgridvisible = false,
        xminorgridvisible = false,
        xminorticksvisible = false,
        xticksvisible = false,
        xticklabelsvisible = false,
        xlabelvisible = true,
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
        #limits = (xlim_topo, ylim_topo),
    )
end

"""
    df_grouping(df, bin_width; col_y = :erp, fun = mean, grouping = [])
Group `DataFrame` according to topoplot coordinates and apply aggregation function.

Arguments:
- `df::AbstractTable`\\
    Requires columns `:cont_cuts`, `col_y` (default `:erp`), and all columns in `grouping` (`col_coord`, `row_coord`, `label`);
- `col_y = :erp` \\
    The column to combine over (with `fun`);
- `fun = mean()`\\
    Function to combine.
- `grouping = []`\\
    Vector of symbols or strings, columns to group by the data before aggregation. Values of `nothing` are ignored.

**Return Value:** `DataFrame`.
"""
function df_grouping( #rename
    df;
    col_y = :erp,
    fun = mean,
    grouping = [],
)
    df = deepcopy(df) # cut seems to change stuff inplace
    grouping = grouping[.!isnothing.(grouping)]
    df_grouped = groupby(df, unique([:cont_cuts, grouping...]))
    df_combined = combine(df_grouped, col_y => fun)
    rename!(df_combined, names(df_combined)[end] => col_y) # renames estimate_fun to estimate
    return df_combined
end

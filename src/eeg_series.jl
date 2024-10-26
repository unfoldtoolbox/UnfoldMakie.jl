"""
    eeg_array_to_dataframe(data::AbstractMatrix, label_aliases::AbstractVector)
    eeg_array_to_dataframe(data::AbstractVector, label_aliases::AbstractVector)
    eeg_array_to_dataframe(data::Union{AbstractMatrix, AbstractVector{<:Number}})

Helper function converting an array (Matrix or Vector) to a tidy `DataFrame` with columns `:estimate`, `:time` and `:label` (with aliases `:color`, `:group`, `:channel`).

Format of Arrays:\\
- times x condition for plot\\_erp.\\
- channels x time for plot\\_butterfly, plot\\_topoplotseries.\\
- channels for plot\\_topoplot.\\

**Return Value:** `DataFrame`.
"""
eeg_array_to_dataframe(data::Union{AbstractMatrix,AbstractVector{<:Number}}) =
    eeg_array_to_dataframe(data, string.(1:size(data, 1)))

eeg_array_to_dataframe(data::AbstractVector, label_aliases::AbstractVector) =
    eeg_array_to_dataframe(reshape(data, 1, :), label_aliases)

function eeg_array_to_dataframe(data::AbstractMatrix, label_aliases::AbstractVector)
    array_to_df(data, label_aliases) = DataFrame(data', label_aliases)
    array_to_df(data::LinearAlgebra.Adjoint{<:Number,<:AbstractVector}, label_aliases) =
        DataFrame(collect(data)', label_aliases)

    df = array_to_df(data, label_aliases)
    df[!, :time] .= 1:nrow(df)

    df = stack(df, Not([:time]); variable_name = :label_aliases, value_name = "estimate")
    df.color = df.label_aliases
    df.group = df.label_aliases
    df.channel = df.label_aliases
    return df
end

"""
    eeg_topoplot_series(data::DataFrame,
        f,
        data::DataFrame;
        bin_width = nothing,
        bin_num = nothing,
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
        topo_attributes...,
    )
    eeg_topoplot_series!(fig, data::DataFrame; kwargs..)

Plot a series of topoplots. 
The function takes the `combinefun = mean` over the `:time` column of `data`.
- `f` \\
    Figure object. \\
- `data::DataFrame`\\
    Needs the columns `:time` and `y(=:erp)`, and `label(=:label)`. \\
    If `data` is a matrix, it is automatically cast to a dataframe, time bins are in samples, labels are `string.(1:size(data,1))`.
- `bin_width::Real = nothing`\\
    Number specifing the width of bin of continuous x-value in its units.\\
- `bin_num::Real = nothing`\\
    Number of topoplots.\\
    Either `bin_width`, or `bin_num` should be specified. Error if they are both specified\\
    If `mapping.col` or `mapping.row` are categorical `bin_width` and `bin_num` stay as `nothing`.
- `col`, `row = :time` \\
    Specify the field to be divided into columns and rows. The default is `col = :time` to split by the time field and `row = nothing`. \\
    Useful to split by a condition, e.g. `...(..., col = :time, row = :condition)` would result in multiple (as many as different values in `df.condition`) rows of topoplot series.
- `row_labels`, `col_labels = false` \\
    Indicate whether there should be labels in the plots in the first column to indicate the row value and in the last row to indicate the time (typically timerange).
- `combinefun::Function = mean`\\
    Specify how the samples are summarised.\\
    Example functions: `mean`, `median`, `std`.  
- `topo_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot axis.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:topo_default_series))
- `topo_attributes::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot interoplation.\\
    To see all options just type `?Topoplot.topoplot` in REPL.\\
    Defaults: $(supportive_defaults(:topo_default_attributes)).

**Return Value:** `Tuple{Figure, Vector{Any}}`.
"""
function eeg_topoplot_series(
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix};
    figure = NamedTuple(),
    kwargs...,
)
    return eeg_topoplot_series!(Figure(; figure...), data; kwargs...)
end

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
    return eeg_topoplot_series(eeg_array_to_dataframe(data, labels); kwargs...)
end
function eeg_topoplot_series!(
    fig,
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix},
    labels;
    kwargs...,
)
    return eeg_topoplot_series!(fig, eeg_array_to_dataframe(data, labels); kwargs...)
end

function eeg_topoplot_series!(
    fig,
    data::Union{<:Observable{<:DataFrame},<:DataFrame};
    bin_width = nothing,
    bin_num = nothing,
    cat_or_cont_columns = "cont",
    y = :erp,
    label = :label,
    col = :time,
    row = nothing,
    col_labels = false,
    row_labels = false,
    rasterize_heatmaps = true,
    combinefun = mean,
    interactive_scatter = nothing,
    highlight_scatter = false,
    topo_axis = (;),
    topo_attributes = (;),
    positions,
)
    topo_axis = update_axis(supportive_defaults(:topo_default_series); topo_axis...)

    # aggregate the data over time bins
    # using same colormap + contour levels for all plots
    data = _as_observable(data)
    select_col = isnothing(col) ? 1 : unique(to_value(data)[:, :col_coord])
    select_row = isnothing(row) ? 1 : unique(to_value(data)[:, :row_coord])
    if eltype(to_value(data)[!, col]) <: Number
        data_mean = @lift(
            data_binning(
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
    topo_attributes = update_axis(topo_attributes; colorrange = (q_min, q_max))

    # do the col/row plot
    axlist = []
    if interactive_scatter != nothing
        @assert isa(interactive_scatter, Observable)
    end
    for r = 1:length(select_row)
        for c = 1:length(select_col)
            df_single =
                topoplot_subselection(data_mean, col, row, select_col, select_row, r, c)
            single_y = @lift($df_single[:, y])
            if isempty(to_value(single_y)) # exits the loop if there is no data for a new topoplot.
                break
            end

            ax = Axis(
                fig[:, :][r, c];
                topo_axis...,
                xlabel = label_management(cat_or_cont_columns, df_single, col),
            )
            # select labels
            labels = to_value(df_single)[:, label]
            # select data

            topo_attributes = scatter_management(
                single_y,
                topo_attributes,
                highlight_scatter,
                interactive_scatter,
            )
            single_topoplot =
                eeg_topoplot!(ax, to_value(single_y), labels; positions, topo_attributes...)
            if rasterize_heatmaps
                single_topoplot.plots[1].plots[1].rasterize = true
            end
            interactive_toposeries(interactive_scatter, single_topoplot, r, c)
            push!(axlist, ax)
        end
    end
    if typeof(fig) != GridLayout && typeof(fig) != GridLayoutBase.GridSubposition
        colgap!(fig.layout, 0)
    end
    return fig, axlist, topo_attributes[:colorrange]
end

function label_management(cat_or_cont_columns, df_single, col)
    if cat_or_cont_columns == "cat"
        tmp_labels = string(to_value(df_single)[1, col])
    else
        tmp_labels = string(to_value(df_single).cont_cuts[1, :][])
    end
    return tmp_labels
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

function scatter_management( # should be chekec and simplified
    single_y,
    topo_attributes,
    highlight_scatter,
    interactive_scatter,
)
    if highlight_scatter != false || interactive_scatter != nothing
        strokecolor = Observable(repeat([:black], length(to_value(single_y))))
        highlight_feature = (; strokecolor = strokecolor)

        if :label_scatter ∈ keys(topo_attributes) &&
           isa(topo_attributes[:label_scatter], NamedTuple)
            label_scatter = merge(topo_attributes[:label_scatter], highlight_feature)
        else
            label_scatter = highlight_feature
        end
        topo_attributes = update_axis(topo_attributes; label_scatter = label_scatter)
    end
    return topo_attributes
end

function interactive_toposeries(interactive_scatter, single_topoplot, r, c)
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

"""
    data_binning(df; col_y = :erp, fun = mean, grouping = [])
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
function data_binning(df; col_y = :erp, fun = mean, grouping = [])
    df = deepcopy(df) # cut seems to change stuff inplace
    grouping = grouping[.!isnothing.(grouping)]
    df_grouped = groupby(df, unique([:cont_cuts, grouping...]))
    df_combined = combine(df_grouped, col_y => fun)
    rename!(df_combined, names(df_combined)[end] => col_y) # renames estimate_fun to estimate    
    return df_combined
end

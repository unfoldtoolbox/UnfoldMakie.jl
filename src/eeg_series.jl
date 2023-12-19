# Note: This is copied from https://github.com/MakieOrg/TopoPlots.jl/pull/3 because they apparently cannot do a review in ~9month...

"""
Helper function converting a matrix (channel x times) to a tidy dataframe
    with columns :estimate, :time and :label
"""
function eeg_matrix_to_dataframe(data, label)
    df = DataFrame(data', label)
    df[!, :time] .= 1:nrow(df)
    df = stack(df, Not([:time]); variable_name = :label, value_name = "estimate")
    return df
end

"""
function eeg_topoplot_series(data::DataFrame,
    Δbin;
    y=:estimate,
    label=:label,
    col=:time,
    row=nothing,
    figure = NamedTuple(),
    combinefun=mean,
    row_labels = false,
    col_labels = false,
    topoplot_attributes...
    )

Plot a series of topoplots. The function automatically takes the `combinefun=mean` over the `:time` column of `data` in `Δbin` steps.
- The data frame `data` needs the columns `:time` and `y(=:erp)`, and `label(=:label)`. 
    If `data` is a matrix, it is automatically cast to a dataframe, time bins are in samples, labels are `string.(1:size(data,1))`.
- Δbin in `:time` units, specifying the time steps. All other keyword arguments are passed to the EEG_TopoPlot recipe. 
    In most cases, the user should specify the electrode positions with `positions=pos`.
- The `col` and `row` arguments specify the field to be divided into columns and rows. The default is `col=:time` to split by the time field and `row=nothing`. 
    Useful to split by a condition, e.g. `...(..., col=:time, row=:condition)` would result in multiple (as many as different values in df.condition) rows of topoplot series.
- The `figure` option allows you to include information for plotting the figure. 
    Alternatively, you can pass a fig object `eeg_topoplot_series!(fig, data::DataFrame, Δbin; kwargs..)`.
- `row_labels` and `col_labels` indicate whether there should be labels in the plots in the first column to indicate the row value and in the last row to indicate the time (typically timerange).
    
# Examples
Desc
```julia-repl
julia > df = DataFrame(:erp => repeat(1:63, 100), :time => repeat(1:20, 5 * 63), :label => repeat(1:63, 100)) # fake data
julia > pos = [(1:63) ./ 63 .* (sin.(range(-2 * pi, 2 * pi, 63))) (1:63) ./ 63 .* cos.(range(-2 * pi, 2 * pi, 63))] .* 0.5 .+ 0.5 # fake electrode positions
julia > pos = [Point2.(pos[k, 1], pos[k, 2]) for k in 1:size(pos, 1)]
julia > eeg_topoplot_series(df, 5; positions=pos)
```
"""
function eeg_topoplot_series(data::DataFrame, Δbin; figure = NamedTuple(), kwargs...)
    return eeg_topoplot_series!(Figure(; figure...), data, Δbin; kwargs...)
end
function eeg_topoplot_series(data::AbstractMatrix, Δbin; figure = NamedTuple(), kwargs...)
    return eeg_topoplot_series!(Figure(; figure...), data, Δbin; kwargs...)
end
# allow to specify Δbin as an keyword for nicer readability
eeg_topoplot_series(data::DataFrame; Δbin, kwargs...) =
    eeg_topoplot_series(data, Δbin; kwargs...)
# AbstractMatrix
function eeg_topoplot_series!(fig, data::AbstractMatrix, Δbin; kwargs...)
    return eeg_topoplot_series!(fig, data, string.(1:size(data, 1)), Δbin; kwargs...)
end

# convert a 2D Matrix to the dataframe
function eeg_topoplot_series(data::AbstractMatrix, labels, Δbin; kwargs...)
    return eeg_topoplot_series(eeg_matrix_to_dataframe(data, labels), Δbin; kwargs...)
end
function eeg_topoplot_series!(fig, data::AbstractMatrix, labels, Δbin; kwargs...)
    return eeg_topoplot_series!(fig, eeg_matrix_to_dataframe(data, labels), Δbin; kwargs...)
end

"""
eeg_topoplot_series!(fig, data::DataFrame, Δbin; kwargs..)
In place plotting of topoplot series
see eeg_topoplot_series(data, Δbin) for help
"""
function eeg_topoplot_series!(
    fig,
    data::DataFrame,
    Δbin;
    y = :erp,
    label = :label,
    col = :time,
    row = nothing,
    combinefun = mean,
    col_labels = false,
    row_labels = false,
    rasterize_heatmap = true,
    topoplot_attributes...,
)

    # cannot be made easier right now, but Simon promised a simpler solution "soonish"
    axisOptions = (
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
        limits = ((-0.25, 1.25), (-0.25, 1.25)),
    )

    # aggregate the data over time bins
    data_mean =
        df_timebin(data, Δbin; col_y = y, fun = combinefun, grouping = [label, col, row])

    # using same colormap + contour levels for all plots
    (q_min, q_max) = Statistics.quantile(data_mean[:, y], [0.001, 0.999])
    # make them symmetrical
    q_min = q_max = max(abs(q_min), abs(q_max))
    q_min = -q_min

    topoplot_attributes = merge(
        (
            colorrange = (q_min, q_max),
            contours = (levels = range(q_min, q_max; length = 7),),
        ),
        topoplot_attributes,
    )

    # do the col/row plot

    select_col = isnothing(col) ? 1 : unique(data_mean[:, col])
    select_row = isnothing(row) ? 1 : unique(data_mean[:, row])

    axlist = []
    for r = 1:length(select_row)
        for c = 1:length(select_col)
            ax = Axis(fig[:, :][r, c]; axisOptions...)
            # select one topoplot
            sel = 1 .== ones(size(data_mean, 1)) # select all
            if !isnothing(col)
                sel = sel .&& (data_mean[:, col] .== select_col[c]) # subselect
            end
            if !isnothing(row)
                sel = sel .&& (data_mean[:, row] .== select_row[r]) # subselect
            end
            df_single = data_mean[sel, :]

            # select labels
            labels = df_single[:, label]
            # select data
            d_vec = df_single[:, y]
            # plot it
            ax2 = eeg_topoplot!(ax, d_vec, labels; topoplot_attributes...)

            if rasterize_heatmap
                ax2.plots[1].plots[1].rasterize = true
            end
            if r == length(select_row) && col_labels
                ax.xlabel = string(df_single.time[1])
                ax.xlabelvisible = true
            end
            if c == 1 && length(select_row) > 1 && row_labels
                #@show df_single
                ax.ylabel = string(df_single[1, row])
                ax.ylabelvisible = true
            end
            push!(axlist, ax)
        end
    end
    if typeof(fig) != GridLayout
        colgap!(fig.layout, 0)
    end

    return fig, axlist
end

"""
function df_timebin(df, Δbin; col_y=:erp, fun=mean, grouping=[])
Split or combine dataframe according to equally spaced time bins
- `df` AbstractTable with columns `:time` and `col_y` (default `:erp`), and all columns in `grouping`;
- `Δbin` bin size in `:time` units;
- `col_y` default :erp, the column to combine over (with `fun`);
- `fun` function to combine, default is `mean`;
- `grouping` (vector of symbols/strings) default empty vector, columns to group the data by before aggregating. Values of `nothing` are ignored.
"""
function df_timebin(df, Δbin; col_y = :erp, fun = mean, grouping = [])
    tmin = minimum(df.time)
    tmax = maximum(df.time)

    bins = range(; start = tmin, step = Δbin, stop = tmax)
    df = deepcopy(df) # cut seems to change stuff inplace
    df.time = cut(df.time, bins; extend = true)

    grouping = grouping[.!isnothing.(grouping)]

    df_m = combine(groupby(df, unique([:time, grouping...])), col_y => fun)
    #df_m = combine(groupby(df, Not(y)), y=>fun)
    rename!(df_m, names(df_m)[end] => col_y) # remove the _fun part of the new column
    return df_m
end

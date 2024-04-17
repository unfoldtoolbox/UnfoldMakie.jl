# Note: This is copied from https://github.com/MakieOrg/TopoPlots.jl/pull/3 because they apparently cannot do a review in ~9month...

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
        fig,
        data::DataFrame,
        Δbin;
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
    eeg_topoplot_series!(fig, data::DataFrame, Δbin; kwargs..)

Plot a series of topoplots. 
The function automatically takes the `combinefun = mean` over the `:time` column of `data` in `Δbin` steps.
- `fig` \\
    Figure object. \\
- `data::DataFrame`\\
    Needs the columns `:time` and `y(=:erp)`, and `label(=:label)`. \\
    If `data` is a matrix, it is automatically cast to a dataframe, time bins are in samples, labels are `string.(1:size(data,1))`.
- `Δbin = :time` \\
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

function eeg_topoplot_series!(
    fig,
    data::DataFrame,
    Δbin;
    y = :erp,
    label = :label,
    col = :time,
    row = nothing,
    col_labels = false,
    row_labels = false,
    rasterize_heatmaps = true,
    combinefun = mean,
    xlim_topo = (-0.25, 1.25),
    ylim_topo = (-0.25, 1.25),
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
        limits = (xlim_topo, ylim_topo),
    )
    # aggregate the data over time bins
    # using same colormap + contour levels for all plots
    data_mean =
        df_timebin(data, Δbin; col_y = y, fun = combinefun, grouping = [label, col, row])
    (q_min, q_max) = extract_colorrange(data_mean, y)
    topoplot_attributes = merge(
        (
            colorrange = (q_min, q_max),
            interp_resolution = (128, 128),
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

            if rasterize_heatmaps
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
    if typeof(fig) != GridLayout && typeof(fig) != GridLayoutBase.GridSubposition
        colgap!(fig.layout, 0)
    end

    return fig, axlist
end

"""
    df_timebin(df, Δbin; col_y = :erp, fun = mean, grouping = [])
Split or combine `DataFrame` according to equally spaced time bins.

Arguments:
- `df::AbstractTable`\\
    With columns `:time` and `col_y` (default `:erp`), and all columns in `grouping`;
- `Δbin`\\
    Bin size in `:time` units;
- `col_y = :erp` \\
    The column to combine over (with `fun`);
- `fun = mean()`\\
    Function to combine.
- `grouping = []`\\
    Vector of symbols or strings, columns to group the data by before aggregation. Values of `nothing` are ignored.

**Return Value:** `DataFrame`.
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

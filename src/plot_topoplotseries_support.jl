function row_col_management(n_topoplots, nrows, config)
    if :layout ∈ keys(config.mapping)
        n_cols = Int(ceil(sqrt(n_topoplots)))
        n_rows = Int(ceil(n_topoplots / n_cols))
    else
        n_rows = nrows
        if 0 > n_topoplots / nrows
            @warn "Impossible number of rows, set to 1 row"
            n_rows = 1
        elseif n_topoplots / nrows < 1
            @warn "Impossible number of rows, set n_cols to $(n_topoplots) / rows"
        end
        n_cols = Int(ceil(n_topoplots / n_rows))
    end
    col_coord = repeat(1:n_cols, outer = n_rows)[1:n_topoplots]
    row_coord = repeat(1:n_rows, inner = n_cols)[1:n_topoplots]
    return row_coord, col_coord
end

function bins_estimation(
    continous_value;
    bin_width = nothing,
    bin_num = nothing,
    cat_or_cont_columns = "cont",
)
    c_min = minimum(continous_value)
    c_max = maximum(continous_value)
    if (!isnothing(bin_width) && !isnothing(bin_num))
        error("Ambigious parameters: specify only `bin_width` or `bin_num`.")
    elseif (isnothing(bin_width) && isnothing(bin_num) && cat_or_cont_columns == "cont")
        error(
            "You haven't specified `bin_width` or `bin_num`. Such option is available only with categorical `mapping.col` or `mapping.row`.",
        )
    end
    if isnothing(bin_width)
        bins = range(; start = c_min, length = bin_num + 1, stop = c_max)
    else
        bins = range(; start = c_min, step = bin_width, stop = c_max)
    end
    return bins
end

function number_of_topoplots(
    df::DataFrame;
    bin_width = nothing,
    bin_num = nothing,
    bins,
    mapping = config.mapping,
)
    if !isnothing(bin_width) | !isnothing(bin_num)
        if typeof(df[:, mapping.col]) == Vector{String}
            error(
                "Parameters `bin_width` or `bin_num` are only allowed with continonus `mapping.col` or `mapping.row`, while you specifed categorical.",
            )
        end
        cont_new = cut(df[:, mapping.col], bins; extend = true)
        n = length(unique(cont_new))
    else
        n = length(unique(df[:, mapping.col]))
    end
    return n
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
function data_binning(df; col_y = :erp, fun = mean, grouping = [], cont_cuts)
    df_grouped = deepcopy(df) # cut seems to change stuff inplace
    df_grouped.cont_cuts = string.(cont_cuts.val)

    grouping = grouping[.!isnothing.(grouping)]
    df_grouped = groupby(df_grouped, unique([:cont_cuts, grouping...]))
    df_combined = combine(df_grouped, col_y => fun)
    rename!(df_combined, names(df_combined)[end] => col_y) # renames estimate_fun to estimate    
    return df_combined
end

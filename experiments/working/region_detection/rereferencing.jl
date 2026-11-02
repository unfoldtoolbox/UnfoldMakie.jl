using CSV
using DataFrames
using Statistics


@isdefined(load_erp_subject) || include("../stimuli_data.jl")

"""
    ERP_ESTIMATES_AVGREF_DIR

Default output directory for cached ERP subject tables with average-reference
columns added alongside the raw `estimate` and `abs_t` columns.
"""
const ERP_ESTIMATES_AVGREF_DIR =
    joinpath("experiments", "erp_estimates_avgref")

const AVGREF_GROUP_COLS = [:subject, :task, :condition, :timepoint]

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Helper: build the cache filepath for one average-referenced subject table.
function avgref_filepath(
    task;
    subject,
    timepoint = 92,
    condition = 1,
    outdir = ERP_ESTIMATES_AVGREF_DIR,
)
    joinpath(
        outdir,
        "erpcore_$(subject)_$(task)_tp$(timepoint)_cond$(condition)_avgref.csv",
    )
end

# Helper: stop if average-reference columns already exist in the loaded table.
function _check_avgref_columns_absent!(subject_data)
    columns = Set(Symbol.(names(subject_data)))
    :estimate_avgref in columns &&
        error("`estimate_avgref` already exists. Refusing to run average rereferencing twice.")
    :abs_t_avgref in columns &&
        error("`abs_t_avgref` already exists. Refusing to run average rereferencing twice.")
    nothing
end

# Helper: ensure the input table has the columns needed for average rereferencing.
function _check_avgref_input_columns!(subject_data; group_cols = AVGREF_GROUP_COLS)
    columns = Set(Symbol.(names(subject_data)))
    required = [:estimate, :se, group_cols...]
    missing_columns = [column for column in required if !(column in columns)]
    isempty(missing_columns) ||
        error("Average rereferencing requires columns: $(join(string.(missing_columns), ", ")).")
    nothing
end

# Helper: read cached average-referenced voltage values.
function avgref_signal(subject_data)
    hasproperty(subject_data, :estimate_avgref) ||
        error("Missing `estimate_avgref`. Load the processed avgref table instead of the raw ERP table.")
    Float64.(subject_data.estimate_avgref)
end

# Helper: read cached average-referenced |t|-like values.
function avgref_abs_t(subject_data)
    hasproperty(subject_data, :abs_t_avgref) ||
        error("Missing `abs_t_avgref`. Load the processed avgref table instead of the raw ERP table.")
    Float64.(subject_data.abs_t_avgref)
end

# -----------------------------------------------------------------------------
# Average-reference preprocessing cache
# -----------------------------------------------------------------------------

"""
    add_average_reference_columns(subject_data; group_cols = AVGREF_GROUP_COLS, atol = 1e-10)

Add cached average-reference columns to a raw ERP estimate table without
overwriting the original `estimate` or `abs_t` columns.

Within each `group_cols` group, the mean `estimate` across channels is
subtracted from every row to create `estimate_avgref`. The function then
recomputes `abs_t_avgref = abs(estimate_avgref) / se`.

The function refuses to run if `estimate_avgref` or `abs_t_avgref` already
exists, which protects against accidental double preprocessing.
"""
function add_average_reference_columns(
    subject_data;
    group_cols = AVGREF_GROUP_COLS,
    atol = 1e-10,
)
    _check_avgref_columns_absent!(subject_data)
    _check_avgref_input_columns!(subject_data; group_cols = group_cols)

    processed = copy(subject_data)
    group_means = combine(
        groupby(processed, group_cols),
        :estimate => (values -> mean(Float64.(values))) => :group_mean_estimate,
    )
    processed = leftjoin(processed, group_means; on = group_cols)
    processed.estimate_avgref =
        Float64.(processed.estimate) .- Float64.(processed.group_mean_estimate)
    processed.abs_t_avgref = abs.(processed.estimate_avgref) ./ Float64.(processed.se)
    select!(processed, Not(:group_mean_estimate))

    validation = combine(
        groupby(processed, group_cols),
        :estimate_avgref => (values -> mean(Float64.(values))) => :mean_estimate_avgref,
    )
    failed = validation[abs.(Float64.(validation.mean_estimate_avgref)) .> atol, :]
    isempty(failed) ||
        error("Average-reference validation failed: group means are not approximately zero.")

    processed
end

"""
    preprocess_average_reference_subject(
        task; subject, timepoint = 92, condition = 1,
        loader = load_erp_subject_or_nothing,
        outdir = ERP_ESTIMATES_AVGREF_DIR,
        atol = 1e-10,
    )
    preprocess_average_reference_subject(
        cfg::NamedTuple; subject,
        loader = load_erp_subject_or_nothing,
        outdir = ERP_ESTIMATES_AVGREF_DIR,
        atol = 1e-10,
    )

Load one raw ERP subject table, add `estimate_avgref` and `abs_t_avgref`,
save the processed table as CSV, and return its filepath.

If the raw subject table cannot be loaded and `loader(...)` returns `nothing`,
the function returns `nothing`.
"""
function preprocess_average_reference_subject(
    task;
    subject,
    timepoint = 92,
    condition = 1,
    loader = load_erp_subject_or_nothing,
    outdir = ERP_ESTIMATES_AVGREF_DIR,
    atol = 1e-10,
)
    subject_data = loader(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
    )
    isnothing(subject_data) && return nothing

    processed = add_average_reference_columns(subject_data; atol = atol)
    filepath = avgref_filepath(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
        outdir = outdir,
    )
    mkpath(dirname(filepath))
    CSV.write(filepath, processed)
    filepath
end

function preprocess_average_reference_subject(
    cfg::NamedTuple;
    subject,
    loader = load_erp_subject_or_nothing,
    outdir = ERP_ESTIMATES_AVGREF_DIR,
    atol = 1e-10,
)
    preprocess_average_reference_subject(
        cfg.task;
        subject = subject,
        timepoint = cfg.timepoint,
        condition = cfg.condition,
        loader = loader,
        outdir = outdir,
        atol = atol,
    )
end

"""
    preprocess_average_reference_all_tasks(
        configs;
        loader = load_erp_subject_or_nothing,
        outdir = ERP_ESTIMATES_AVGREF_DIR,
        atol = 1e-10,
    )

Compute cached average-reference ERP tables for every subject listed in
`configs` and save the processed CSV files under `outdir`.

Each saved file keeps the raw `estimate` and `abs_t` columns and adds
`estimate_avgref` and `abs_t_avgref`.
"""
function preprocess_average_reference_all_tasks(
    configs;
    loader = load_erp_subject_or_nothing,
    outdir = ERP_ESTIMATES_AVGREF_DIR,
    atol = 1e-10,
)
    filepaths = String[]

    for cfg in configs
        for subject in cfg.subjects
            filepath = preprocess_average_reference_subject(
                cfg;
                subject = subject,
                loader = loader,
                outdir = outdir,
                atol = atol,
            )
            isnothing(filepath) && continue
            push!(filepaths, filepath)
        end
    end

    (
        outdir = outdir,
        filepaths = filepaths,
    )
end

"""
    load_erp_subject_avgref(
        task; subject, timepoint = 92, condition = 1,
        outdir = ERP_ESTIMATES_AVGREF_DIR,
    )

Load a cached average-referenced ERP subject table saved by
[`preprocess_average_reference_subject`](@ref).
"""
function load_erp_subject_avgref(
    task;
    subject,
    timepoint = 92,
    condition = 1,
    outdir = ERP_ESTIMATES_AVGREF_DIR,
)
    filepath = avgref_filepath(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
        outdir = outdir,
    )
    isfile(filepath) || error("Processed avgref file does not exist: $filepath")
    CSV.read(filepath, DataFrame)
end

"""
    load_erp_subject_avgref_or_nothing(
        task; subject, timepoint = 92, condition = 1,
        outdir = ERP_ESTIMATES_AVGREF_DIR,
    )

Load a cached average-referenced ERP subject table if it exists, otherwise
return `nothing`.
"""
function load_erp_subject_avgref_or_nothing(
    task;
    subject,
    timepoint = 92,
    condition = 1,
    outdir = ERP_ESTIMATES_AVGREF_DIR,
)
    filepath = avgref_filepath(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
        outdir = outdir,
    )
    isfile(filepath) || return nothing
    CSV.read(filepath, DataFrame)
end

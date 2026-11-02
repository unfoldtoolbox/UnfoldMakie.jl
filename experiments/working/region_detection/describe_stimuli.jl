using GridLayoutBase

@isdefined(TOPO_REGIONS) || include("geometry.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("rereferencing.jl")

# -----------------------------------------------------------------------------
# 1. Subject range inspection
# -----------------------------------------------------------------------------

# Investigating all subjects to find the best ones.
function subject_topoplot_ranges(
    task;
    subjects,
    timepoint,
    condition,
    check_sym_error = false,
)
    rows = NamedTuple[]

    for subj in subjects
        test = load_erp_subject_avgref_or_nothing(
            task;
            subject = subj,
            timepoint = timepoint,
            condition = condition,
        )
        isnothing(test) && continue

        est = avgref_signal(test)
        est_lo, est_hi = minimum(est), maximum(est)
        row = (
            subject = subj,
            est_lo = est_lo,
            est_hi = est_hi,
            est_span = est_hi - est_lo,
        )

        if check_sym_error
            if est_lo > 0 && est_hi > 0
                row = (
                    ; row...,
                    sym_lo = missing,
                    sym_hi = missing,
                    sym_min_delta = missing,
                    sym_min_error = missing,
                )
            elseif any(<(0), est)
                sym_lo, sym_hi = UnfoldMakie._topo_range_from_values(est)
                row = (
                    ; row...,
                    sym_lo = sym_lo,
                    sym_hi = sym_hi,
                    sym_min_delta = sym_lo - est_lo,
                    sym_min_error = abs(sym_lo - est_lo),
                )
            else
                row = (
                    ; row...,
                    sym_lo = est_lo,
                    sym_hi = est_hi,
                    sym_min_delta = 0f0,
                    sym_min_error = 0f0,
                )
            end
        end

        push!(rows, row)
    end

    DataFrame(rows)
end


# -----------------------------------------------------------------------------
# 2. Range table summaries
# -----------------------------------------------------------------------------

# Helpers for `describe_sss_ranges`.
function _finite_span(values)
    vals = collect(filter(isfinite, vec(values)))
    isempty(vals) && return missing
    lo, hi = extrema(vals)
    return hi - lo
end

function describe_sss_ranges(configs)
    rows = NamedTuple[]

    for cfg in configs
        for subj in cfg.subjects
            test = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subj,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )
            isnothing(test) && continue

            signal = avgref_signal(test)
            se = test.se
            snr = avgref_abs_t(test)

            push!(rows, (
                task = cfg.task,
                subject = subj,
                case = "$(cfg.task)_$(subj)",
                signal_range = _finite_span(signal),
                se_range = _finite_span(se),
                snr_range = _finite_span(snr),
            ))
        end
    end

    DataFrame(rows)
end


include("../debug/debug_sss.jl")


# -----------------------------------------------------------------------------
# 4. Faceted distribution plots
# -----------------------------------------------------------------------------

# Helpers for `plot_sss_ranges_faceted`.
function _task_subject_from_case(case)
    parts = split(String(case), "_"; limit = 2)
    length(parts) == 2 || error("Could not parse task/subject from case=$(repr(case)).")
    task = parts[1]
    subject = something(tryparse(Int, parts[2]), parts[2])
    return task, subject
end

function long_sss_ranges(df)
    rows = NamedTuple[]
    score_specs = (
        (:signal_range, "Signal"),
        (:se_range, "SE"),
        (:snr_range, "SNR"),
    )
    columns = Set(Symbol.(names(df)))
    has_task = :task in columns
    has_subject = :subject in columns
    has_case = :case in columns

    (!has_case && (!has_task || !has_subject)) &&
        error("Data frame must contain `case`, or both `task` and `subject` columns.")

    for row in eachrow(df)
        case_name = has_case ? row.case : "$(row.task)_$(row.subject)"
        parsed_task, parsed_subject = _task_subject_from_case(case_name)
        task = has_task ? row.task : parsed_task
        subject = has_subject ? row.subject : parsed_subject

        for (col, score) in score_specs
            value = row[col]
            (ismissing(value) || !isfinite(value)) && continue

            push!(rows, (
                task = task,
                subject = subject,
                case = case_name,
                score = score,
                value = Float64(value),
            ))
        end
    end

    DataFrame(rows)
end

function _ordered_values(values, preferred_order)
    ordered = [value for value in preferred_order if value in values]

    for value in values
        value in ordered || push!(ordered, value)
    end

    ordered
end

function plot_sss_ranges_faceted(
    df;
    task_order = ["MMN", "N170", "P3"],
    score_order = ["Signal", "SE", "SNR"],
    scale_mode = :shared,
    title = "Signal, SE, and SNR ranges by task",
)
    long_df = long_sss_ranges(df)
    isempty(long_df) && error("No signal/SE/SNR rows available to plot.")

    tasks = _ordered_values(unique(long_df.task), task_order)
    score_colors = Dict(
        "Signal" => "#4E79A7",
        "SE" => "#F28E2B",
        "SNR" => "#59A14F",
    )

    fig = Figure(
        size = (430 * length(tasks), 430),
        figure_padding = (16, 16, 24, 16),
    )
    Label(fig[0, :], title, fontsize = 24)

    axes = Axis[]
    shared_y_hi = maximum(long_df.value)
    shared_y_pad = iszero(shared_y_hi) ? 1.0 : 0.08 * shared_y_hi

    for (task_idx, task) in enumerate(tasks)
        ax = Axis(
            fig[1, task_idx],
            title = task,
            xlabel = "Score",
            ylabel = task_idx == 1 ? "Range" : "",
            xticks = (1:length(score_order), score_order),
            xgridvisible = false,
        )
        push!(axes, ax)

        task_df = long_df[long_df.task .== task, :]
        for (score_idx, score_name) in enumerate(score_order)
            values = Float64.(task_df[task_df.score .== score_name, :value])
            isempty(values) && continue

            if length(values) > 1
                boxplot!(
                    ax,
                    fill(score_idx, length(values)),
                    values;
                    color = score_colors[score_name],
                    show_outliers = false,
                    whiskerwidth = 0.45,
                    width = 0.72,
                )
            end

            # Spread dots deterministically so all participants remain visible.
            offsets = length(values) == 1 ? [0.0] : collect(range(-0.18, 0.18; length = length(values)))
            scatter!(
                ax,
                fill(score_idx, length(values)) .+ offsets,
                sort(values);
                color = (:black, 0.72),
                markersize = 11,
                strokecolor = :white,
                strokewidth = 1,
            )
        end

        if scale_mode == :shared
            ylims!(ax, 0, shared_y_hi + shared_y_pad)
        elseif scale_mode == :task_relative
            task_y_hi = maximum(task_df.value)
            task_y_pad = iszero(task_y_hi) ? 1.0 : 0.08 * task_y_hi
            ylims!(ax, 0, task_y_hi + task_y_pad)
        else
            error("Unknown scale_mode=$(repr(scale_mode)). Use :shared or :task_relative.")
        end
    end

    scale_mode == :shared && linkyaxes!(axes...)
    colgap!(fig.layout, 14)

    fig
end


# -----------------------------------------------------------------------------
# Example calls / scratch work
# -----------------------------------------------------------------------------

p3_ranges = subject_topoplot_ranges(
    "P3";
    subjects = 1:30,
    timepoint = 129,
    condition = 1,
)

mmn_ranges = subject_topoplot_ranges(
    "MMN";
    subjects = 1:30,
    timepoint = 96,
    condition = 3,
)


n170_ranges = subject_topoplot_ranges(
    "N170";
    subjects = 1:30,
    timepoint = 105,
    condition = 2,
)

### check the error 
p3_ranges =subject_topoplot_ranges(
    "P3";
    subjects =[1, 2, 4, 7, 8, 10, 12, 13, 16, 19],# 1:30,
    timepoint = 129,
    condition = 1,
    check_sym_error = true,
)

mmn_ranges = subject_topoplot_ranges(
    "MMN";
    subjects = 1:30,
    timepoint = 96,
    condition = 3,
    check_sym_error = true,
)

n170_ranges = subject_topoplot_ranges(
    "N170";
    subjects = 1:30,
    timepoint = 105,
    condition = 2,
    check_sym_error = true,
)
####

# Shared task config sets live in `experiments/working/stimuli_data.jl`.

sss_ranges_30 = describe_sss_ranges(task_configs_30)

sss_ranges_all = describe_sss_ranges(task_configs_all)

sss_ranges_all[sss_ranges_all.case .== "MMN_1", :]

sss_range_fig_all = plot_sss_ranges_faceted(
    sss_ranges_all;
    scale_mode = :task_relative,
)


pages = sss_pages(task_configs_30)
pages[1]

normalised_pages = sss_pages(task_configs_30; normalise = true)
normalised_pages[1]


filepath = sss_pdf(
    task_configs_30;
    filepath = "experiments/figures/all_tasks_sss_a4.pdf",
    normalise = false,
)

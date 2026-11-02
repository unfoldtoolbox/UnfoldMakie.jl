using Printf: @sprintf

@isdefined(TOPO_REGIONS) || include("geometry.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("rereferencing.jl")
@isdefined(region_weights_from_grid) || include("scoring.jl")

# Rescale region scores into the [0, 1] interval.
function normalise_region_scores(raw_scores)
    valid = [Float64(value) for value in values(raw_scores) if isfinite(value)]
    isempty(valid) && error("No valid region scores.")

    lo, hi = extrema(valid)

    Dict(
        label => begin
            value = raw_scores[label]
            if !isfinite(value)
                NaN
            elseif hi == lo
                0.0
            else
                Float64((value - lo) / (hi - lo))
            end
        end
        for label in keys(raw_scores)
    )
end

# Round final normalised scores for easier inspection in the returned rows.
function rounded_scores(scores; digits = 2)
    Dict(
        label => (isfinite(value) ? round(Float64(value), digits = digits) : value)
        for (label, value) in pairs(scores)
    )
end

# Compute the same rounded normalized region scores shown in pipeline panel 7.
function subject_region_scores(
    subject_data;
    regions = TOPO_REGIONS,
    agg = :mean,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    digits = 2,
)
    raw_snr = avgref_abs_t(subject_data)

    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, raw_snr; labels = subject_data.labels)
    tp = h.plots[1]

    rows_t = region_weights_from_grid(
        tp.xg[],
        tp.yg[],
        tp.mask[] .* tp.data_interpolated[],
        regions;
        agg = agg,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        mask = tp.mask[],
        topoplot_domain = region_head_domain_from_plot(h),
        n_bins = 8,
        binning = :quantile,
        reverse = false,
    )

    raw_scores = Dict(String(row.label) => Float64(row.raw_score) for row in rows_t)

    (
        raw_snr = raw_snr,
        raw_scores = raw_scores,
        scores = rounded_scores(normalise_region_scores(raw_scores); digits = digits),
    )
end

# Build region scores where each region gets a value from 0 to 1.
function make_region_score(
    configs;
    regions = TOPO_REGIONS,
    agg = :mean,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
)
    rows = NamedTuple[]

    for cfg in configs
        for subject in cfg.subjects
            subject_data = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )
            isnothing(subject_data) && continue

            region_scores = subject_region_scores(
                subject_data;
                regions = regions,
                agg = agg,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
            )

            push!(rows, (
                stimulus = "$(cfg.task)_$(subject)",
                task = cfg.task,
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
                raw_scores = region_scores.raw_scores,
                scores = region_scores.scores,
            ))
        end
    end

    rows
end

# Build pipeline-panel-7 style rounded normalized region scores for each stimulus.
function make_region_score_panel7(
    configs;
    regions = TOPO_REGIONS,
    agg = :mean,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    digits = 2,
)
    rows = NamedTuple[]

    for cfg in configs
        for subject in cfg.subjects
            subject_data = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )
            isnothing(subject_data) && continue

            region_scores = subject_region_scores(
                subject_data;
                regions = regions,
                agg = agg,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                digits = digits,
            )

            push!(rows, (
                stimulus = "$(cfg.task)_$(subject)",
                task = cfg.task,
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
                raw_scores = region_scores.raw_scores,
                scores = region_scores.scores,
            ))
        end
    end

    rows
end

function _top_score_labels(scores)
    valid = [
        (label = String(label), value = Float64(value)) for (label, value) in pairs(scores) if isfinite(value)
    ]
    isempty(valid) && return String[]

    top_value = maximum(row.value for row in valid)
    sort([row.label for row in valid if row.value == top_value])
end

function _score_values_match(left, right; atol = 0.0)
    if isnan(left) && isnan(right)
        true
    elseif isfinite(left) && isfinite(right)
        isapprox(Float64(left), Float64(right); atol = atol, rtol = 0.0)
    else
        false
    end
end

# Compare two region-score tables stimulus by stimulus and label by label.
function compare_region_score_rows(left_rows, right_rows; atol = 0.0)
    left_by_stimulus = Dict(row.stimulus => row for row in left_rows)
    right_by_stimulus = Dict(row.stimulus => row for row in right_rows)

    left_stimuli = sort(collect(keys(left_by_stimulus)))
    right_stimuli = sort(collect(keys(right_by_stimulus)))
    shared_stimuli = sort(collect(intersect(Set(left_stimuli), Set(right_stimuli))))
    missing_left = sort(setdiff(right_stimuli, left_stimuli))
    missing_right = sort(setdiff(left_stimuli, right_stimuli))

    mismatches = NamedTuple[]

    for stimulus in shared_stimuli
        left_scores = left_by_stimulus[stimulus].scores
        right_scores = right_by_stimulus[stimulus].scores
        left_labels = sort(collect(keys(left_scores)))
        right_labels = sort(collect(keys(right_scores)))

        if left_labels != right_labels
            push!(mismatches, (
                stimulus = stimulus,
                reason = :label_mismatch,
                left_top = _top_score_labels(left_scores),
                right_top = _top_score_labels(right_scores),
                max_abs_diff = NaN,
                differing_scores = NamedTuple[],
                labels_only_left = sort(setdiff(left_labels, right_labels)),
                labels_only_right = sort(setdiff(right_labels, left_labels)),
            ))
            continue
        end

        differing_scores = NamedTuple[]
        max_abs_diff = 0.0

        for label in left_labels
            left_value = left_scores[label]
            right_value = right_scores[label]
            _score_values_match(left_value, right_value; atol = atol) && continue

            abs_diff = if isfinite(left_value) && isfinite(right_value)
                abs(Float64(left_value) - Float64(right_value))
            else
                Inf
            end
            max_abs_diff = max(max_abs_diff, abs_diff)

            push!(differing_scores, (
                label = String(label),
                left = left_value,
                right = right_value,
                abs_diff = abs_diff,
            ))
        end

        isempty(differing_scores) && continue
        sort!(differing_scores; by = row -> row.abs_diff, rev = true)

        push!(mismatches, (
            stimulus = stimulus,
            reason = :score_mismatch,
            left_top = _top_score_labels(left_scores),
            right_top = _top_score_labels(right_scores),
            max_abs_diff = max_abs_diff,
            differing_scores = differing_scores,
            labels_only_left = String[],
            labels_only_right = String[],
        ))
    end

    (
        matches = isempty(missing_left) && isempty(missing_right) && isempty(mismatches),
        compared_stimuli = shared_stimuli,
        case_count = length(shared_stimuli),
        missing_left = missing_left,
        missing_right = missing_right,
        mismatches = mismatches,
    )
end

function format_region_score_comparison(report; max_cases = 8, max_scores = 5)
    if report.matches
        return "region score check: matched $(report.case_count) stimulus/stimuli"
    end

    lines = String[
        "region score check: mismatches found",
        "shared stimuli: $(report.case_count)",
    ]

    isempty(report.missing_left) || push!(lines, "missing in left: " * join(report.missing_left, ", "))
    isempty(report.missing_right) || push!(lines, "missing in right: " * join(report.missing_right, ", "))

    for mismatch in first(report.mismatches, min(max_cases, length(report.mismatches)))
        push!(
            lines,
            @sprintf(
                "%s | reason=%s | left_top=%s | right_top=%s | max_abs_diff=%.4f",
                mismatch.stimulus,
                String(mismatch.reason),
                join(mismatch.left_top, "/"),
                join(mismatch.right_top, "/"),
                mismatch.max_abs_diff,
            ),
        )

        if mismatch.reason == :score_mismatch
            for score_row in first(mismatch.differing_scores, min(max_scores, length(mismatch.differing_scores)))
                push!(
                    lines,
                    @sprintf(
                        "  %s: left=%.2f right=%.2f abs_diff=%.4f",
                        score_row.label,
                        score_row.left,
                        score_row.right,
                        score_row.abs_diff,
                    ),
                )
            end
        end
    end

    join(lines, "\n")
end

region_score_dict(rows) = Dict(
    row.stimulus => Dict(label => row.scores[label] for label in sort(collect(keys(row.scores))))
    for row in rows
)

function format_region_score(rows; fn_name = "region_scores")
    lines = ["<?php", "", "function $(fn_name)() {", "    return array("]

    for row in rows
        score_text = join(
            ["\"$(label)\" => " * @sprintf("%.2f", row.scores[label]) for label in sort(collect(keys(row.scores)))],
            ", ",
        )
        push!(lines, "        \"$(row.stimulus)\" => array($(score_text)),")
    end

    push!(lines, "    );", "}")
    join(lines, "\n")
end

function format_region_score_value_arrays(rows; fn_name = "region_scores")
    lines = ["<?php", "", "function $(fn_name)() {", "    return array("]

    for row in rows
        value_text = join(
            [@sprintf("%.2f", row.scores[label]) for label in sort(collect(keys(row.scores)))],
            ", ",
        )
        push!(lines, "        \"$(row.stimulus)\" => array($(value_text)),")
    end

    push!(lines, "    );", "}")
    join(lines, "\n")
end

function save_region_score(rows, path; fn_name = "region_scores")
    text = format_region_score(rows; fn_name = fn_name)
    write(path, text * "\n")
    path
end

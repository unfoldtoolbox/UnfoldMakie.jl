using Printf: @sprintf

@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")

const SSS_COLORBAR_WIDTH = 130
const SSS_PORTRAIT_PT = (595, 842)
const SSS_LANDSCAPE_PT = (842, 595)

# Return finite min/max limits, with a safe fallback for empty or constant arrays.
function _sss_limits(values)
    vals = Float32[Float32(value) for value in vec(values) if isfinite(value)]
    isempty(vals) && return (0f0, 1f0)

    lo, hi = extrema(vals)
    if lo == hi
        return lo == 0f0 ? (0f0, 1f0) : (lo - abs(lo) * 0.05f0, hi + abs(hi) * 0.05f0)
    end

    (lo, hi)
end

# Build a balanced color range for voltage topoplots.
function _sss_signal_limits(values)
    vals = Float32[Float32(value) for value in vec(values) if isfinite(value)]
    isempty(vals) && return (-1f0, 1f0)
    hi = maximum(abs, vals)
    hi <= 0f0 && return (-1f0, 1f0)
    (-hi, hi)
end

# Build a non-negative color range for SNR values.
function _sss_snr_limits(values)
    vals = Float32[Float32(value) for value in vec(values) if isfinite(value)]
    isempty(vals) && return (0f0, 1f0)

    hi = maximum(vals)
    hi <= 0f0 && return (0f0, 1f0)
    (0f0, hi)
end

# Format simple colorbar ticks and labels.
function _sss_ticks(limits; nticks = 5)
    lo, hi = Float64.(limits)
    if !isfinite(lo) || !isfinite(hi)
        return ([0.0], ["0.0"])
    end
    if lo == hi
        return ([lo], [@sprintf("%.1f", lo)])
    end

    ticks = collect(LinRange(lo, hi, nticks))
    labels = [@sprintf("%.1f", tick) for tick in ticks]
    (ticks, labels)
end

# Rescale one numeric array into the [0, 1] interval.
function _sss_zero_one(values; limits)
    lo, hi = Float32.(limits)
    hi == lo && return fill(0f0, size(values))

    out = similar(values, Float32)
    for idx in eachindex(values)
        value = values[idx]
        out[idx] = isfinite(value) ? clamp(Float32((value - lo) / (hi - lo)), 0f0, 1f0) : Float32(value)
    end

    out
end

# Load one task and compute signal/SE/SNR per subject.
function _sss_task(cfg; normalise = false, rereference_voltage = true)
    raw_rows = NamedTuple[]

    for subject in cfg.subjects
        subject_data = load_erp_subject_avgref_or_nothing(
            cfg.task;
            subject = subject,
            timepoint = cfg.timepoint,
            condition = cfg.condition,
        )
        isnothing(subject_data) && continue

        signal = rereference_voltage ? avgref_signal(subject_data) : Float64.(subject_data.estimate)
        se = Float64.(subject_data.se)

        push!(raw_rows, (
            subject = subject,
            labels = subject_data.labels,
            signal = signal,
            se = se,
        ))
    end

    isempty(raw_rows) && return nothing
#= 
    if normalise
        signal_all = reduce(vcat, [row.signal for row in raw_rows])
        se_all = reduce(vcat, [row.se for row in raw_rows])
        signal_source_limits = _sss_limits(signal_all)
        se_source_limits = _sss_limits(se_all)
        rows = NamedTuple[]

        for row in raw_rows
            signal = _sss_zero_one(row.signal; limits = signal_source_limits)
            se = _sss_zero_one(row.se; limits = se_source_limits)
            snr = abs.(signal ./ max.(se, eps(Float32)))

            push!(rows, (
                subject = row.subject,
                labels = row.labels,
                signal = signal,
                se = se,
                snr = snr,
            ))
        end

        return (
            task = cfg.task,
            rows = rows,
        )
    end =#

    rows = NamedTuple[]

    for row in raw_rows
        snr = abs.(row.signal ./ row.se)
        push!(rows, (
            subject = row.subject,
            labels = row.labels,
            signal = row.signal,
            se = row.se,
            snr = snr,
        ))
    end

    (
        task = cfg.task,
        rows = rows,
    )
end

# Split prepared task rows into A4-sized pages.
function _sss_page_specs(
    configs;
    normalise = false,
    page_height_pt = SSS_PORTRAIT_PT[2],
    row_height = 160,
    rows_per_page = nothing,
    rereference_voltage = true,
)
    tasks = [
        task_data for cfg in configs
        for task_data in (_sss_task(
            cfg;
            normalise = normalise,
            rereference_voltage = rereference_voltage,
        ),)
        if !isnothing(task_data)
    ]
    isempty(tasks) && error("No SSS data available to plot.")

    page_rows = isnothing(rows_per_page) ? max(1, floor(Int, (page_height_pt - 110) / row_height)) : rows_per_page
    pages = NamedTuple[]

    for task_data in tasks
        n_pages = cld(length(task_data.rows), page_rows)

        for page_idx in 1:n_pages
            row_start = 1 + (page_idx - 1) * page_rows
            row_stop = min(page_idx * page_rows, length(task_data.rows))
            title = n_pages == 1 ? task_data.task : "$(task_data.task) ($(page_idx)/$(n_pages))"

            push!(pages, (
                title = title,
                rows = task_data.rows[row_start:row_stop],
            ))
        end
    end

    pages
end

# Build one page figure with three topoplots per subject row.
function _sss_figure(page; page_size_pt = SSS_PORTRAIT_PT, figure_padding = (18, 18, 24, 18))
    fig = Figure(size = page_size_pt, figure_padding = figure_padding)
    grid = fig[1, 1] = GridLayout()
    colgap!(grid, 12)
    rowgap!(grid, 16)
    Label(grid[0, 1:3], page.title, fontsize = 28)

    for (row_idx, row) in enumerate(page.rows)
        subject_label = "subject $(row.subject)"
        signal_limits = _sss_signal_limits(row.signal)
        se_limits = _sss_limits(row.se)
        snr_limits = _sss_snr_limits(row.snr)

        plot_topoplot!(
            grid[row_idx, 1],
            row.signal;
            labels = row.labels,
            axis = (;
                title = row_idx == 1 ? "Signal" : "",
                titlesize = 22,
                xlabel = subject_label,
                xlabelsize = 18,
            ),
            visual = (;
                colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
                colorrange = signal_limits,
                contours = false,
            ),
            colorbar = (;
                label = "",
                vertical = false,
                position = :bottom,
                width = SSS_COLORBAR_WIDTH,
                ticks = _sss_ticks(signal_limits),
            ),
            layout = (; use_colorbar = true),
        )

        plot_topoplot!(
            grid[row_idx, 2],
            row.se;
            labels = row.labels,
            axis = (;
                title = row_idx == 1 ? "SE" : "",
                titlesize = 22,
                xlabel = "",
            ),
            visual = (;
                colormap = cgrad(:viridis, 10; categorical = true),
                colorrange = se_limits,
                contours = false,
            ),
            colorbar = (;
                label = "",
                vertical = false,
                position = :bottom,
                width = SSS_COLORBAR_WIDTH,
                ticks = _sss_ticks(se_limits),
            ),
            layout = (; use_colorbar = true),
        )

        plot_topoplot!(
            grid[row_idx, 3],
            row.snr;
            labels = row.labels,
            axis = (;
                title = row_idx == 1 ? "SNR" : "",
                titlesize = 22,
                xlabel = "",
            ),
            visual = (;
                colormap = cgrad(:batlow, 10; categorical = true),
                colorrange = snr_limits,
                contours = false,
            ),
            colorbar = (;
                label = "",
                vertical = false,
                position = :bottom,
                width = SSS_COLORBAR_WIDTH,
                ticks = _sss_ticks(snr_limits),
            ),
            layout = (; use_colorbar = true),
        )
    end

    fig
end

# Build all SSS PDF pages as Makie figures.
function sss_pages(
    configs;
    normalise = false,
    orientation = :portrait,
    figure_padding = (18, 18, 24, 18),
    row_height = 160,
    rows_per_page = nothing,
    rereference_voltage = true,
)
    page_size_pt = orientation == :portrait ? SSS_PORTRAIT_PT : SSS_LANDSCAPE_PT
    pages = _sss_page_specs(
        configs;
        normalise = normalise,
        page_height_pt = page_size_pt[2],
        row_height = row_height,
        rows_per_page = rows_per_page,
        rereference_voltage = rereference_voltage,
    )

    [
        _sss_figure(
            page;
            page_size_pt = page_size_pt,
            figure_padding = figure_padding,
        )
        for page in pages
    ]
end

# Save all SSS pages into one PDF file.
function sss_pdf(
    configs;
    filepath = "experiments/figures/all_tasks_sss_a4.pdf",
    normalise = false,
    orientation = :portrait,
    figure_padding = (18, 18, 24, 18),
    row_height = 160,
    rows_per_page = nothing,
    rereference_voltage = true,
)
    figs = sss_pages(
        configs;
        normalise = normalise,
        orientation = orientation,
        figure_padding = figure_padding,
        row_height = row_height,
        rows_per_page = rows_per_page,
        rereference_voltage = rereference_voltage,
    )
    isempty(figs) && error("No SSS pages were generated.")

    mkpath(dirname(filepath))

    if length(figs) == 1
        save(filepath, only(figs); pt_per_unit = 1)
        return filepath
    end

    pdfunite = Sys.which("pdfunite")
    isnothing(pdfunite) && error("`pdfunite` is required to merge multiple SSS pages into one PDF.")

    tmpdir = mktempdir()
    pagepaths = String[]

    try
        for (page_idx, fig) in enumerate(figs)
            pagepath = joinpath(tmpdir, "page_$(lpad(string(page_idx), 3, '0')).pdf")
            save(pagepath, fig; pt_per_unit = 1)
            push!(pagepaths, pagepath)
        end

        run(Cmd(vcat([pdfunite], pagepaths, [filepath])))
    finally
        rm(tmpdir; recursive = true, force = true)
    end

    filepath
end

#=
filepath = sss_pdf(
    task_configs_30;
    filepath = "experiments/figures/all_tasks_sss_a4.pdf",
    normalise = false,
    orientation = :portrait,
    rereference_voltage = true,
)
=#

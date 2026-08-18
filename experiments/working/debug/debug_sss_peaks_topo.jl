using Printf: @sprintf

@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")
@isdefined(TOPO_REGIONS) || include("../region_detection/geometry.jl")
@isdefined(region_weights_from_grid) || include("../region_detection/scoring.jl")
@isdefined(plot_region_weight_topoplot!) || include("../region_detection/plotting.jl")

function _sss_region_scores_load_saved_region_const(filepath, const_name::Symbol)
    scratch = Module(gensym(:SavedSSSPeaksTopoRegions))
    Core.eval(scratch, Meta.parse(read(filepath, String)))
    Core.eval(scratch, const_name)
end

function _sss_region_scores_saved_eeg_aligned_pipeline28_regions()
    filepath = joinpath(
        "experiments",
        "figures",
        "task2_topo_regions_64_eeg_aligned_pipeline28",
        "regions.jl",
    )
    _sss_region_scores_load_saved_region_const(
        filepath,
        :TOPO_REGIONS_64_EEG_ALIGNED_PIPELINE28,
    )
end

const SSS_REGION_SCORES_PT = (595, 842)
const SSS_REGION_SCORES_BG = RGBf(0.98, 0.98, 0.98)
const SSS_REGION_SCORES_CMAP = cgrad(:batlow, 10; categorical = true)
const SSS_REGION_SCORES_PALETTE = Dict(i => SSS_REGION_SCORES_CMAP[i] for i in 1:10)

# Reuse only rereferenced values and turn the estimate panel into a nonnegative score map.
function _sss_region_scores_estimate_field(subject_data)
    signal = avgref_signal(subject_data)
    out = similar(signal, Float64)

    for idx in eachindex(signal)
        value = signal[idx]
        out[idx] = isfinite(value) ? abs(Float64(value)) : NaN
    end

    out
end

# Use the cached rereferenced SNR values directly.
function _sss_region_scores_snr_field(subject_data)
    snr = avgref_abs_t(subject_data)
    out = similar(snr, Float64)

    for idx in eachindex(snr)
        value = snr[idx]
        out[idx] = isfinite(value) ? Float64(value) : NaN
    end

    out
end

# Normalise one region-score dictionary into [0, 1].
function _sss_region_scores_normalise(raw_scores)
    valid = [Float64(value) for value in values(raw_scores) if isfinite(value)]
    isempty(valid) && error("No valid region scores were available.")

    lo, hi = extrema(valid)

    Dict(
        label => begin
            score = raw_scores[label]
            if !isfinite(score)
                NaN
            elseif hi == lo
                0.0
            else
                Float64((score - lo) / (hi - lo))
            end
        end
        for label in keys(raw_scores)
    )
end

# Pick the region with the largest raw score so the footer can compare estimate vs SNR.
function _sss_region_scores_argmax(raw_scores)
    best_label = missing
    best_score = -Inf

    for label in sort!(collect(keys(raw_scores)))
        score = raw_scores[label]
        isfinite(score) || continue

        if score > best_score
            best_score = score
            best_label = String(label)
        end
    end

    best_label
end

# Convert one field into the same region-grid score representation used in pipeline panel 7.
function _sss_region_scores_panel_data(
    values,
    labels;
    agg = :mean,
    regions = TOPO_REGIONS,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    use_rendered_domain_as_source = false,
)
    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(
        tmpax,
        values;
        labels = labels,
        contours = false,
        clip = false,
        label_text = false,
    )
    tp = h.plots[1]
    domain = region_head_domain_from_plot(h)
    source_head_center = use_rendered_domain_as_source ?
        (domain.center[1], domain.center[2]) :
        head_center
    source_head_radius = use_rendered_domain_as_source ? domain.radius : head_radius

    rows = region_weights_from_grid(
        tp.xg[],
        tp.yg[],
        tp.mask[] .* tp.data_interpolated[],
        regions;
        agg = agg,
        template_center = template_center,
        template_radius = template_radius,
        head_center = source_head_center,
        head_radius = source_head_radius,
        mask = tp.mask[],
        topoplot_domain = domain,
        n_bins = 10,
        binning = :quantile,
        reverse = false,
    )

    raw_scores = Dict(String(row.label) => Float64(row.raw_score) for row in rows)
    scores = _sss_region_scores_normalise(raw_scores)
    weights = Dict(
        label => begin
            score = scores[label]
            isfinite(score) ? clamp(floor(Int, score * 10) + 1, 1, 10) : 0
        end
        for label in keys(scores)
    )
    region_text = Dict(
        label => (isfinite(scores[label]) ? @sprintf("%.2f", scores[label]) : "")
        for label in keys(scores)
    )

    (
        raw_scores = raw_scores,
        scores = scores,
        weights = weights,
        region_text = region_text,
        argmax = _sss_region_scores_argmax(raw_scores),
        regions = regions,
        topoplot_domain = domain,
        template_center = template_center,
        template_radius = template_radius,
        head_center = source_head_center,
        head_radius = source_head_radius,
    )
end

# Build one case row containing two panel-7-style region maps.
function sss_peaks_topo_rows(
    configs;
    agg = :mean,
    regions = TOPO_REGIONS,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    use_rendered_domain_as_source = false,
)
    rows = NamedTuple[]
    skipped = 0

    for cfg in configs
        for subject in cfg.subjects
            subject_data = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )

            if isnothing(subject_data)
                skipped += 1
                continue
            end

            estimate_panel = _sss_region_scores_panel_data(
                _sss_region_scores_estimate_field(subject_data),
                subject_data.labels;
                agg = agg,
                regions = regions,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                use_rendered_domain_as_source = use_rendered_domain_as_source,
            )
            snr_panel = _sss_region_scores_panel_data(
                _sss_region_scores_snr_field(subject_data),
                subject_data.labels;
                agg = agg,
                regions = regions,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                use_rendered_domain_as_source = use_rendered_domain_as_source,
            )

            estimate_argmax = estimate_panel.argmax
            snr_argmax = snr_panel.argmax
            same_argmax =
                !ismissing(estimate_argmax) &&
                !ismissing(snr_argmax) &&
                estimate_argmax == snr_argmax

            push!(rows, (
                task = cfg.task,
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
                labels = subject_data.labels,
                estimate = estimate_panel,
                snr = snr_panel,
                estimate_argmax = estimate_argmax,
                snr_argmax = snr_argmax,
                same_argmax = same_argmax,
            ))
        end
    end

    isempty(rows) && error("No cached avgref cases were found for the region-score PDF.")
    skipped > 0 && println("skipped $skipped case(s) with missing avgref CSV files")

    rows
end

function _sss_region_scores_panel!(
    slot,
    panel_data;
    title,
    plot_width = 126,
    plot_height = 124,
    title_size = 12,
    value_size = 7,
)
    ax = Axis(
        slot;
        aspect = DataAspect(),
        backgroundcolor = SSS_REGION_SCORES_BG,
        title = title,
        titlesize = title_size,
        xlabel = "",
        width = plot_width,
        height = plot_height,
        xautolimitmargin = (0.02, 0.02),
        yautolimitmargin = (0.03, 0.06),
    )
    hidedecorations!(ax, label = false)
    hidespines!(ax)

    plot_region_weight_topoplot!(
        ax,
        panel_data.weights;
        regions = panel_data.regions,
        show_labels = false,
        missing_color = :white,
        strokecolor = :black,
        strokewidth = 0.95,
        palette = SSS_REGION_SCORES_PALETTE,
        topoplot_domain = panel_data.topoplot_domain,
        template_center = panel_data.template_center,
        template_radius = panel_data.template_radius,
        region_center = panel_data.head_center,
        head_radius = panel_data.head_radius,
    )

    fitted = fit_region_polygons_to_domain(
        panel_data.regions,
        panel_data.topoplot_domain;
        template_center = panel_data.template_center,
        template_radius = panel_data.template_radius,
        head_center = panel_data.head_center,
        head_radius = panel_data.head_radius,
    )
    for (reg, poly) in zip(panel_data.regions, fitted.polygons)
        center = polygon_centroid(poly)
        text!(
            ax,
            center;
            text = get(panel_data.region_text, string(reg.label), ""),
            align = (:center, :center),
            fontsize = value_size,
            color = :black,
        )
    end

    ax
end

function _sss_region_scores_case!(slot, row)
    case_gl = slot[] = GridLayout()
    colgap!(case_gl, 10)
    rowgap!(case_gl, 4)
    case_id = "$(row.task)_$(row.subject)"

    Label(
        case_gl[1, 1:2],
        "$case_id | $(row.timepoint) ms | condition $(row.condition)";
        fontsize = 13,
        font = :bold,
    )

    _sss_region_scores_panel!(
        case_gl[2, 1],
        row.estimate;
        title = "Estimate",
    )

    _sss_region_scores_panel!(
        case_gl[2, 2],
        row.snr;
        title = "SNR",
    )

    footer_text, footer_color = if row.same_argmax
        ("same max region\n$(row.estimate_argmax)", RGBf(0.10, 0.45, 0.20))
    else
        (
            "different max regions\nest: $(row.estimate_argmax) | snr: $(row.snr_argmax)",
            RGBf(0.75, 0.16, 0.16),
        )
    end

    Label(
        case_gl[3, 1:2],
        footer_text;
        fontsize = 9,
        color = footer_color,
        lineheight = 0.95,
    )

    rowsize!(case_gl, 1, Fixed(20))
    rowsize!(case_gl, 3, Fixed(34))
    colsize!(case_gl, 1, Fixed(128))
    colsize!(case_gl, 2, Fixed(128))
end

function _sss_region_scores_figure(page_rows; page_idx = 1, page_count = 1)
    fig = Figure(
        size = SSS_REGION_SCORES_PT,
        backgroundcolor = SSS_REGION_SCORES_BG,
        figure_padding = (18, 18, 14, 14),
    )
    outer = fig[1, 1] = GridLayout()
    rowgap!(outer, 10)

    title = page_count == 1 ?
        "Rereferenced Estimate vs SNR Region Scores" :
        "Rereferenced Estimate vs SNR Region Scores ($(page_idx)/$(page_count))"
    Label(outer[1, 1], title; fontsize = 22, font = :bold)
    Label(
        outer[2, 1],
        "Estimate uses |rereferenced voltage|, SNR uses rereferenced |voltage| / SE. Both maps reuse the panel-7 region grid and are normalised to [0, 1] per case.";
        fontsize = 9,
        tellwidth = false,
    )

    cases_gl = outer[3, 1] = GridLayout()
    colgap!(cases_gl, 18)
    rowgap!(cases_gl, 18)

    for (idx, row) in enumerate(page_rows)
        grid_row = cld(idx, 2)
        grid_col = mod1(idx, 2)
        _sss_region_scores_case!(cases_gl[grid_row, grid_col], row)
    end

    shared_gl = outer[4, 1] = GridLayout()
    Colorbar(
        shared_gl[1, 1];
        colormap = SSS_REGION_SCORES_CMAP,
        limits = (0.0, 1.0),
        ticks = (0.0:0.25:1.0, string.(0.0:0.25:1.0)),
        label = "Normalised score [0, 1]",
        labelsize = 14,
        ticklabelsize = 10,
        width = 240,
        vertical = false,
        labelrotation = 2π,
    )

    n_case_cols = min(2, length(page_rows))
    for col_idx in 1:n_case_cols
        colsize!(cases_gl, col_idx, Fixed(266))
    end
    rowsize!(outer, 4, Fixed(52))

    fig
end

function sss_peaks_topo_pages(
    configs;
    cases_per_page = 4,
    agg = :mean,
    regions = TOPO_REGIONS,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    use_rendered_domain_as_source = false,
)
    rows = sss_peaks_topo_rows(
        configs;
        agg = agg,
        regions = regions,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        use_rendered_domain_as_source = use_rendered_domain_as_source,
    )
    pages = [rows[idx:min(idx + cases_per_page - 1, length(rows))] for idx in 1:cases_per_page:length(rows)]

    [
        _sss_region_scores_figure(page_rows; page_idx = page_idx, page_count = length(pages))
        for (page_idx, page_rows) in enumerate(pages)
    ]
end

function sss_peaks_topo_pdf(
    configs;
    filepath = joinpath("experiments", "pdfs", "30_cases_sss_peaks_topo.pdf"),
    keep_page_pdfs = false,
    cases_per_page = 4,
    agg = :mean,
    regions = TOPO_REGIONS,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    use_rendered_domain_as_source = false,
)
    figs = sss_peaks_topo_pages(
        configs;
        cases_per_page = cases_per_page,
        agg = agg,
        regions = regions,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        use_rendered_domain_as_source = use_rendered_domain_as_source,
    )

    mkpath(dirname(filepath))
    pdfunite = Sys.which("pdfunite")
    isnothing(pdfunite) && error("`pdfunite` is required to merge pages into one PDF.")

    tmpdir = mktempdir()
    pagepaths = String[]

    try
        for (page_idx, fig) in enumerate(figs)
            pagepath = joinpath(tmpdir, "page_$(lpad(string(page_idx), 3, '0')).pdf")
            save(pagepath, fig; pt_per_unit = 1)
            push!(pagepaths, pagepath)
        end

        if length(pagepaths) == 1
            cp(only(pagepaths), filepath; force = true)
        else
            run(Cmd(vcat([pdfunite], pagepaths, [filepath])))
        end

        if keep_page_pdfs
            pages_dir = joinpath(dirname(filepath), basename(filepath) * "_pages")
            mkpath(pages_dir)
            for pagepath in pagepaths
                cp(pagepath, joinpath(pages_dir, basename(pagepath)); force = true)
            end
        end
    finally
        rm(tmpdir; recursive = true, force = true)
    end

    filepath
end

function sss_peaks_topo_pdf_64_eeg_grid(
    configs;
    filepath = joinpath("experiments", "pdfs", "64grid_30_cases_sss_peaks_topo.pdf"),
    keep_page_pdfs = false,
    cases_per_page = 4,
    agg = :mean,
)
    sss_peaks_topo_pdf(
        configs;
        filepath = filepath,
        keep_page_pdfs = keep_page_pdfs,
        cases_per_page = cases_per_page,
        agg = agg,
        regions = _sss_region_scores_saved_eeg_aligned_pipeline28_regions(),
        use_rendered_domain_as_source = true,
    )
end

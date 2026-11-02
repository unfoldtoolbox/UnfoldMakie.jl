using Printf: @sprintf

@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")
@isdefined(TOPO_REGIONS) || include("../region_detection/geometry.jl")
@isdefined(region_weights_from_grid) || include("../region_detection/scoring.jl")
@isdefined(extract_topoplot_grid) || include("../region_detection/plotting.jl")

function _sss_peaks_load_saved_region_const(filepath, const_name::Symbol)
    scratch = Module(gensym(:SavedSSSPeaksRegions))
    Core.eval(scratch, Meta.parse(read(filepath, String)))
    Core.eval(scratch, const_name)
end

function _sss_peaks_saved_eeg_aligned_pipeline28_regions()
    filepath = joinpath(
        "experiments",
        "figures",
        "task2_topo_regions_64_eeg_aligned_pipeline28",
        "regions.jl",
    )
    _sss_peaks_load_saved_region_const(filepath, :TOPO_REGIONS_64_EEG_ALIGNED_PIPELINE28)
end

# Use |rereferenced voltage| for the estimate-region comparison.
function _sss_peaks_region_signal(subject_data)
    abs.(Float64.(avgref_signal(subject_data)))
end

# Use cached rereferenced |voltage| / SE values for the SNR-region comparison.
function _sss_peaks_region_snr(subject_data)
    Float64.(avgref_abs_t(subject_data))
end

# Convert one channel field into raw region scores with the same grid-based scoring as the pipeline.
function _sss_peaks_region_raw_scores(
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
    xg, yg, _, zmask = extract_topoplot_grid(h)
    domain = region_head_domain_from_plot(h)
    source_head_center = use_rendered_domain_as_source ?
        (domain.center[1], domain.center[2]) :
        head_center
    source_head_radius = use_rendered_domain_as_source ? domain.radius : head_radius

    rows = region_weights_from_grid(
        xg,
        yg,
        zmask,
        regions;
        agg = agg,
        template_center = template_center,
        template_radius = template_radius,
        head_center = source_head_center,
        head_radius = source_head_radius,
        mask = h.plots[1].mask[],
        topoplot_domain = domain,
        n_bins = 10,
        binning = :quantile,
        reverse = false,
    )

    Dict(String(row.label) => Float64(row.raw_score) for row in rows)
end

# Pick the region with the largest raw score and return both the label and score.
function _sss_peaks_region_argmax(raw_scores)
    best_label = missing
    best_score = missing

    for label in sort!(collect(keys(raw_scores)))
        score = raw_scores[label]
        isfinite(score) || continue

        if ismissing(best_score) || score > best_score
            best_label = label
            best_score = score
        end
    end

    (label = best_label, score = best_score)
end

function sss_peaks_by_regions_rows(
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

    for cfg in configs
        for subject in cfg.subjects
            subject_data = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )

            if isnothing(subject_data)
                push!(rows, (
                    task = cfg.task,
                    subject = subject,
                    max_abs_ref_signal_region = missing,
                    argmax_signal_region = missing,
                    max_snr_region = missing,
                    argmax_snr_region = missing,
                    delta = missing,
                ))
                continue
            end

            signal_scores = _sss_peaks_region_raw_scores(
                _sss_peaks_region_signal(subject_data),
                subject_data.labels;
                agg = agg,
                regions = regions,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                use_rendered_domain_as_source = use_rendered_domain_as_source,
            )
            snr_scores = _sss_peaks_region_raw_scores(
                _sss_peaks_region_snr(subject_data),
                subject_data.labels;
                agg = agg,
                regions = regions,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                use_rendered_domain_as_source = use_rendered_domain_as_source,
            )

            signal_peak = _sss_peaks_region_argmax(signal_scores)
            snr_peak = _sss_peaks_region_argmax(snr_scores)

            push!(rows, (
                task = cfg.task,
                subject = subject,
                max_abs_ref_signal_region = signal_peak.score,
                argmax_signal_region = signal_peak.label,
                max_snr_region = snr_peak.score,
                argmax_snr_region = snr_peak.label,
                delta = snr_peak.score - signal_peak.score,
            ))
        end
    end

    rows
end

function sss_peaks_by_regions_pdf(
    configs;
    filepath = joinpath("experiments", "pdfs", "all_cases_sss_peaks_by_regions.pdf"),
    agg = :mean,
    regions = TOPO_REGIONS,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    use_rendered_domain_as_source = false,
)
    rows = sss_peaks_by_regions_rows(
        configs;
        agg = agg,
        regions = regions,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        use_rendered_domain_as_source = use_rendered_domain_as_source,
    )

    html_escape(text) = replace(
        string(text),
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "\"" => "&quot;",
        "'" => "&#39;",
    )

    format_value(value) = ismissing(value) ? "missing" : @sprintf("%.4f", value)

    table_rows = join([
        begin
            row_class = any(ismissing, (
                row.max_abs_ref_signal_region,
                row.argmax_signal_region,
                row.max_snr_region,
                row.argmax_snr_region,
                row.delta,
            )) ? "missing" : ""
            task_subject_class = row_class == "missing" ? "cell-missing" :
                row.argmax_signal_region == row.argmax_snr_region ? "cell-match" : "cell-mismatch"
            """
            <tr class="$row_class">
              <td class="$task_subject_class">$(html_escape(row.task))</td>
              <td class="$task_subject_class">$(html_escape(row.subject))</td>
              <td>$(format_value(row.max_abs_ref_signal_region))</td>
              <td>$(html_escape(row.argmax_signal_region))</td>
              <td>$(format_value(row.max_snr_region))</td>
              <td>$(html_escape(row.argmax_snr_region))</td>
              <td>$(format_value(row.delta))</td>
            </tr>
            """
        end
        for row in rows
    ], "\n")

    html = """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>SSS Peaks By Regions</title>
      <style>
        @page {
          size: A4 portrait;
          margin: 18mm;
        }

        body {
          font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
          color: #1f2937;
          margin: 0;
          background: white;
        }

        h1 {
          margin: 0 0 14px 0;
          font-size: 22px;
          letter-spacing: 0.02em;
        }

        .subtitle {
          margin: 0 0 20px 0;
          font-size: 12px;
          color: #6b7280;
        }

        table {
          width: 100%;
          border-collapse: collapse;
          table-layout: fixed;
          font-size: 13px;
        }

        thead {
          display: table-header-group;
        }

        tr {
          page-break-inside: avoid;
        }

        th {
          text-align: left;
          padding: 10px 12px;
          border-bottom: 2px solid #d1d5db;
          background: #f3f4f6;
          font-weight: 700;
        }

        td {
          padding: 8px 12px;
          border-bottom: 1px solid #e5e7eb;
          vertical-align: top;
          word-wrap: break-word;
        }

        tbody tr:nth-child(even) {
          background: #fafafa;
        }

        tbody tr.missing {
          background: #fef2f2;
          color: #991b1b;
        }

        td.cell-match {
          background: #dcfce7;
          color: #166534;
          font-weight: 700;
        }

        td.cell-mismatch {
          background: #fef3c7;
          color: #92400e;
          font-weight: 700;
        }

        td.cell-missing {
          background: #fee2e2;
          color: #991b1b;
          font-weight: 700;
        }

        .col-task { width: 14%; }
        .col-subject { width: 10%; }
        .col-signal { width: 16%; }
        .col-signal-region { width: 14%; }
        .col-snr { width: 14%; }
        .col-snr-region { width: 14%; }
        .col-delta { width: 18%; }
      </style>
    </head>
    <body>
      <h1>Referenced Signal Region Peak vs SNR Region Peak</h1>
      <p class="subtitle">SNR is computed as rereferenced |Voltage| / SE and estimate uses |rereferenced voltage| before region aggregation.</p>
      <p class="subtitle">Region scores come from the interpolated topoplot grid across $(length(regions)) regions using `agg = $(html_escape(agg))`.</p>
      <table>
        <thead>
          <tr>
            <th class="col-task">task</th>
            <th class="col-subject">subject</th>
            <th class="col-signal">max_signal_region</th>
            <th class="col-signal-region">argmax_signal_region</th>
            <th class="col-snr">max_snr_region</th>
            <th class="col-snr-region">argmax_snr_region</th>
            <th class="col-delta">delta</th>
          </tr>
        </thead>
        <tbody>
          $table_rows
        </tbody>
      </table>
    </body>
    </html>
    """

    mkpath(dirname(filepath))

    browser = something(Sys.which("google-chrome"), Sys.which("chromium"))
    isnothing(browser) && error("Need `google-chrome` or `chromium` to convert the HTML table to PDF.")
    tmpdir = mktempdir()

    try
        htmlpath = joinpath(tmpdir, "sss_peaks_by_regions.html")
        open(htmlpath, "w") do io
            write(io, html)
        end

        file_url = "file://" * abspath(htmlpath)
        user_data_dir = joinpath(tmpdir, "chrome-profile")
        mkpath(user_data_dir)

        cmd = Cmd([
            browser,
            "--headless",
            "--disable-gpu",
            "--disable-dev-shm-usage",
            "--disable-crash-reporter",
            "--disable-logging",
            "--log-level=3",
            "--no-sandbox",
            "--no-pdf-header-footer",
            "--user-data-dir=$(user_data_dir)",
            "--print-to-pdf=$(abspath(filepath))",
            file_url,
        ])

        try
            run(pipeline(cmd; stdout = devnull, stderr = devnull))
        catch
            error("Browser failed while converting the SSS region-peaks HTML table to PDF.")
        end
    finally
        rm(tmpdir; recursive = true, force = true)
    end

    filepath
end

function sss_peaks_by_regions_pdf_64_eeg_grid(
    configs;
    filepath = joinpath("experiments", "pdfs", "64grid_30_cases_sss_peaks_by_regions.pdf"),
    agg = :mean,
)
    sss_peaks_by_regions_pdf(
        configs;
        filepath = filepath,
        agg = agg,
        regions = _sss_peaks_saved_eeg_aligned_pipeline28_regions(),
        use_rendered_domain_as_source = true,
    )
end

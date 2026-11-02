using Printf: @sprintf

@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")

function sss_peaks_rows(configs)
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
                    max_abs_ref_signal = missing,
                    argmax_signal = missing,
                    max_snr = missing,
                    argmax_snr = missing,
                    delta = missing,
                ))
                continue
            end

            ref_signal = avgref_signal(subject_data)
            se = Float64.(subject_data.se)
            snr = abs.(ref_signal ./ se)
            abs_ref_signal = abs.(ref_signal)
            signal_idx = argmax(abs_ref_signal)
            snr_idx = argmax(snr)
            max_abs_ref_signal = abs_ref_signal[signal_idx]
            max_snr = snr[snr_idx]

            push!(rows, (
                task = cfg.task,
                subject = subject,
                max_abs_ref_signal = max_abs_ref_signal,
                argmax_signal = subject_data.labels[signal_idx],
                max_snr = max_snr,
                argmax_snr = subject_data.labels[snr_idx],
                delta = max_snr - max_abs_ref_signal,
            ))
        end
    end

    rows
end

function sss_peaks_pdf(
    configs;
    filepath = joinpath("experiments", "pdfs", "30_cases_sss_peaks.pdf"),
)
    rows = sss_peaks_rows(configs)

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
                row.max_abs_ref_signal,
                row.argmax_signal,
                row.max_snr,
                row.argmax_snr,
                row.delta,
            )) ? "missing" : ""
            task_subject_class = row_class == "missing" ? "cell-missing" :
                row.argmax_signal == row.argmax_snr ? "cell-match" : "cell-mismatch"
            """
            <tr class="$row_class">
              <td class="$task_subject_class">$(html_escape(row.task))</td>
              <td class="$task_subject_class">$(html_escape(row.subject))</td>
              <td>$(format_value(row.max_abs_ref_signal))</td>
              <td>$(html_escape(row.argmax_signal))</td>
              <td>$(format_value(row.max_snr))</td>
              <td>$(html_escape(row.argmax_snr))</td>
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
      <title>SSS Peaks</title>
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
        .col-signal-channel { width: 14%; }
        .col-snr { width: 14%; }
        .col-snr-channel { width: 14%; }
        .col-delta { width: 18%; }
      </style>
    </head>
    <body>
      <h1>Referenced Signal Peak vs SNR</h1>
      <p class="subtitle">SNR is computed as |Voltage / Standard Error| using referenced voltage and the unreferenced SE column.</p>
      <p class="subtitle">Signal is rereferenced and we used absolute values.</p>
      <table>
        <thead>
          <tr>
            <th class="col-task">task</th>
            <th class="col-subject">subject</th>
            <th class="col-signal">max_signal</th>
            <th class="col-signal-channel">argmax_signal</th>
            <th class="col-snr">max_snr</th>
            <th class="col-snr-channel">argmax_snr</th>
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
        htmlpath = joinpath(tmpdir, "sss_peaks.html")
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
            error("Browser failed while converting the SSS peaks HTML table to PDF.")
        end
    finally
        rm(tmpdir; recursive = true, force = true)
    end

    filepath
end

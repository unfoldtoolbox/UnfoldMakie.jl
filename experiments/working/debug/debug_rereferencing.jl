using Printf: @sprintf
using Statistics: mean

@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")

function rereferencing_rows(configs; atol = 1e-10)
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
                    timepoint = cfg.timepoint,
                    value = missing,
                    status = "FAIL",
                ))
                continue
            end

            value = mean(avgref_signal(subject_data))
            value = abs(value) <= atol ? 0.0 : Float64(value)
            status = abs(value) <= atol ? "OK" : "FAIL"

            push!(rows, (
                task = cfg.task,
                subject = subject,
                timepoint = cfg.timepoint,
                value = value,
                status = status,
            ))
        end
    end

    rows
end

function print_rereferencing_table(rows)
    green = "\e[32m"
    red = "\e[31m"
    reset = "\e[0m"

    println(rpad("task", 10), rpad("subject", 10), rpad("timepoint", 12), rpad("value", 18), "Status")

    for row in rows
        color = row.status == "OK" ? green : red
        value_text = ismissing(row.value) ? "missing" : @sprintf("%.3e", row.value)

        println(
            color,
            rpad(string(row.task), 10),
            rpad(string(row.subject), 10),
            rpad(string(row.timepoint), 12),
            rpad(value_text, 18),
            row.status,
            reset,
        )
    end

    nothing
end

function rereferencing_pdf(
    configs;
    filepath = joinpath("experiments", "pdfs", "30_cases_rereferencing.pdf"),
    atol = 1e-10,
)
    rows = rereferencing_rows(configs; atol = atol)
    print_rereferencing_table(rows)

    mkpath(dirname(filepath))

    html_escape(text) = replace(
        string(text),
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "\"" => "&quot;",
        "'" => "&#39;",
    )

    format_value(value) = ismissing(value) ? "missing" : @sprintf("%.3e", value)

    table_rows = join([
        begin
            row_class = row.status == "OK" ? "ok" : "fail"
            """
            <tr class="$row_class">
              <td>$(html_escape(row.task))</td>
              <td>$(html_escape(row.subject))</td>
              <td>$(html_escape(row.timepoint))</td>
              <td>$(format_value(row.value))</td>
              <td>$(html_escape(row.status))</td>
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
      <title>Rereferencing Check</title>
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
          margin: 0 0 12px 0;
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

        tbody tr.ok {
          background: #f0fdf4;
          color: #166534;
        }

        tbody tr.fail {
          background: #fef2f2;
          color: #991b1b;
        }

        .col-task { width: 22%; }
        .col-subject { width: 18%; }
        .col-timepoint { width: 18%; }
        .col-value { width: 24%; }
        .col-status { width: 18%; }
      </style>
    </head>
    <body>
      <h1>Average Rereferencing Check</h1>
      <p class="subtitle">For each case, the mean rereferenced voltage across channels should be approximately zero.</p>
      <table>
        <thead>
          <tr>
            <th class="col-task">task</th>
            <th class="col-subject">subject</th>
            <th class="col-timepoint">timepoint</th>
            <th class="col-value">value</th>
            <th class="col-status">status</th>
          </tr>
        </thead>
        <tbody>
          $table_rows
        </tbody>
      </table>
    </body>
    </html>
    """

    browser = something(Sys.which("google-chrome"), Sys.which("chromium"))
    isnothing(browser) && error("Need `google-chrome` or `chromium` to convert the rereferencing table to PDF.")
    tmpdir = mktempdir()

    try
        htmlpath = joinpath(tmpdir, "rereferencing.html")
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
            error("Browser failed while converting the rereferencing HTML table to PDF.")
        end
    finally
        rm(tmpdir; recursive = true, force = true)
    end

    filepath
end

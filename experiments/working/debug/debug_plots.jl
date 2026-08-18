@isdefined(plot_combined_uncerts) || include("../plot_fitting/combined_plots.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")

# Build one combined-uncertainty figure from the cached rereferenced CSV table.
function combined_case_figure(
    task;
    subject,
    timepoint,
    condition,
    title = nothing,
    figure_size = (1700, 700),
    figure_padding = (20, 20, 20, 10),
    include_hop = false,
    return_hop = false,
    hop_n_boot = 20,
    hop_rng = nothing,
    triple_topo_size = nothing,
    triple_colorbar_gap = nothing,
)
    subject_data = load_erp_subject_avgref_or_nothing(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
    )
    isnothing(subject_data) && return nothing

    signal = avgref_signal(subject_data)
    se = Float64.(subject_data.se)

    plot_result = plot_combined_uncerts(
        signal,
        se;
        labels = subject_data.labels,
        uncert_label = "Std Error",
        figure_size = figure_size,
        figure_padding = figure_padding,
        layout_mode = :wide,
        panel_label_fontsize = 26,
        include_hop = include_hop,
        return_hop = return_hop,
        hop_n_boot = hop_n_boot,
        hop_rng = hop_rng,
        triple_topo_size = triple_topo_size,
        triple_colorbar_gap = triple_colorbar_gap,
    )
    fig = return_hop ? plot_result.figure : plot_result
    case_id = "$(task)_$(subject)"

    Label(
        fig[0, 1:3],
        something(title, "$case_id | $(timepoint) ms | condition $condition");
        fontsize = 30,
        font = :bold,
        halign = :center,
        tellwidth = false,
        padding = (0, 0, 18, 0),
    )
    rowgap!(fig.layout, 1, 18)

    return return_hop ? (; figure = fig, hop_obs = plot_result.hop_obs, hop_boot_means = plot_result.hop_boot_means) : fig
end

function combined_case_hop_gif(
    task;
    subject,
    timepoint,
    condition,
    filepath = joinpath("experiments", "figures", "$(task)_$(subject)_combined_uncerts_hop.gif"),
    title = nothing,
    figure_size = (1700, 700),
    figure_padding = (20, 20, 20, 10),
    hop_n_boot = 20,
    hop_rng = nothing,
    triple_topo_size = nothing,
    triple_colorbar_gap = nothing,
)
    result = combined_case_figure(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
        title = title,
        figure_size = figure_size,
        figure_padding = figure_padding,
        include_hop = true,
        return_hop = true,
        hop_n_boot = hop_n_boot,
        hop_rng = hop_rng,
        triple_topo_size = triple_topo_size,
        triple_colorbar_gap = triple_colorbar_gap,
    )
    isnothing(result) && return nothing

    create_HOP_gif(result.figure, result.hop_obs, result.hop_boot_means; filepath = filepath)
    filepath
end

# Build one figure per available case and skip missing cached rereferenced files.
function combined_pages(
    configs;
    figure_size = (1700, 900),
    figure_padding = (20, 20, 20, 10),
)
    figs = Figure[]
    skipped = 0

    for cfg in configs
        for subject in cfg.subjects
            fig = combined_case_figure(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
                figure_size = figure_size,
                figure_padding = figure_padding,
            )

            if isnothing(fig)
                skipped += 1
                continue
            end

            push!(figs, fig)
        end
    end

    isempty(figs) && error("No cached rereferenced cases were found to plot.")
    skipped > 0 && println("skipped $skipped case(s) with missing avgref CSV files")

    figs
end

# Save all case figures as one merged PDF.
function combined_pdf(
    configs;
    filepath = "experiments/figures/all_cases_combined_uncerts_landscape.pdf",
    figure_size = (1700, 900),
    figure_padding = (20, 20, 20, 10),
    keep_page_pdfs = false,
)
    figs = combined_pages(
        configs;
        figure_size = figure_size,
        figure_padding = figure_padding,
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

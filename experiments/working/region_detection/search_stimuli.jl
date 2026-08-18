@isdefined(TOPO_REGIONS) || include("geometry.jl")
@isdefined(region_weights_from_grid) || include("scoring.jl")
@isdefined(make_region_key) || include("plotting.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("rereferencing.jl")

# Helper: load a cached average-referenced table without falling back to raw ERP files.
function load_search_subject_avgref_or_nothing(cfg; subject)
    load_erp_subject_avgref_or_nothing(
        cfg.task;
        subject = subject,
        timepoint = cfg.timepoint,
        condition = cfg.condition,
    )
end

function build_search_stimuli_figure(
    cfg;
    figure_size = (1600, 1200),
    figure_padding = (10, 10, 24, 24),
    n_cols = 6,
    col_gap = 12,
    row_gap = 18,
    title_size = 28,
)
    fig = Figure(size = figure_size, figure_padding = figure_padding)
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, col_gap)
    rowgap!(gl, row_gap)
    k = 0

    for subj in cfg.subjects
        subject_data = load_search_subject_avgref_or_nothing(cfg; subject = subj)
        isnothing(subject_data) && continue

        k += 1
        i = cld(k, n_cols)
        j = mod1(k, n_cols)
        signal = avgref_signal(subject_data) # magick!

        plot_topoplot!(
            gl[i, j],
            signal;
            labels = subject_data.labels,
            axis = (; xlabel = "", title = "$(cfg.task)_$(subj)", titlesize = title_size),
            colorbar = (; label = "", vertical = false, position = :bottom, width = 180),
            visual = (;
                colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
                contours = true,
            ),
        )
    end

    fig
end

function save_search_stimuli_pdf(
    configs;
    filepath = joinpath("experiments", "pdfs", "all_stimuli_topos.pdf"),
    kwargs...,
)
    mkpath(dirname(filepath))

    pagepaths = String[]
    pdfunite = Sys.which("pdfunite")
    isnothing(pdfunite) && error("`pdfunite` is required to merge pages into one PDF.")

    tmpdir = mktempdir()
    mergedpath = joinpath(tmpdir, "all_stimuli_topos.pdf")

    try
        for (page_idx, cfg) in enumerate(configs)
            fig = build_search_stimuli_figure(cfg; kwargs...)
            pagepath = joinpath(tmpdir, "page_$(lpad(string(page_idx), 3, '0'))_$(cfg.task).pdf")
            save(pagepath, fig; pt_per_unit = 1)
            push!(pagepaths, pagepath)
        end

        isempty(pagepaths) && error("No search stimuli pages were generated.")

        if length(pagepaths) == 1
            cp(only(pagepaths), mergedpath; force = true)
        else
            run(Cmd(vcat([pdfunite], pagepaths, [mergedpath])))
        end

        cp(mergedpath, filepath; force = true)
    finally
        rm(tmpdir; recursive = true, force = true)
    end

    filepath
end

save_search_stimuli_pdf(
    task_configs_all;
    filepath = joinpath("experiments", "pdfs", "all_stimuli_topos.pdf"),
)


save_search_stimuli_pdf(
    task_configs_30;
    filepath = joinpath("experiments", "pdfs", "30_stimuli_topos.pdf"),
)

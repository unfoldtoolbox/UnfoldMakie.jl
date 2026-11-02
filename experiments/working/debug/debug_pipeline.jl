if !@isdefined(Point2f)
    const Point2f = Makie.Point2f
end

@isdefined(plot_region_scoring_pipeline) || include("../region_detection/pipeline_illustration.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")
@isdefined(TOPO_REGIONS) || include("../region_detection/geometry.jl")
@isdefined(region_weights_from_grid) || include("../region_detection/scoring.jl")
@isdefined(plot_region_weight_topoplot!) || include("../region_detection/plotting.jl")

function _load_saved_region_const(filepath, const_name::Symbol)
    scratch = Module(gensym(:SavedPipelineRegions))
    Core.eval(scratch, Meta.parse(read(filepath, String)))
    Core.eval(scratch, const_name)
end

function saved_eeg_aligned_pipeline28_regions()
    filepath = joinpath(
        "experiments",
        "figures",
        "task2_topo_regions_64_eeg_aligned_pipeline28",
        "regions.jl",
    )
    _load_saved_region_const(filepath, :TOPO_REGIONS_64_EEG_ALIGNED_PIPELINE28)
end

# Build one pipeline figure per available case in the config list.
function pipeline_pages(
    configs;
    regions = TOPO_REGIONS_32,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    stage_width = 340,
    stage_height = 300,
)
    figs = Figure[]
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

            fig = plot_region_scoring_pipeline(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
                regions = regions,
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                stage_width = stage_width,
                stage_height = stage_height,
            )
            push!(figs, fig)
        end
    end

    isempty(figs) && error("No cached avgref cases were found for the pipeline PDF.")
    skipped > 0 && println("skipped $skipped case(s) with missing avgref CSV files")

    figs
end

# Save all pipeline figures as one merged PDF.
function pipeline_pdf(
    configs;
    filepath = joinpath("experiments", "pdfs", "30_cases_pipeline.pdf"),
    keep_page_pdfs = false,
    regions = TOPO_REGIONS_32,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    stage_width = 340,
    stage_height = 300,
)
    figs = pipeline_pages(
        configs;
        regions = regions,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        stage_width = stage_width,
        stage_height = stage_height,
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

function pipeline_pdf_64_eeg_grid(
    configs;
    filepath = joinpath("experiments", "pdfs", "64grid_30_cases_pipeline.pdf"),
    keep_page_pdfs = false,
)
    pipeline_pdf(
        configs;
        filepath = filepath,
        keep_page_pdfs = keep_page_pdfs,
        regions = saved_eeg_aligned_pipeline28_regions(),
    )
end

begin
    @isdefined(task_configs_30) || include("../stimuli_data.jl")

    chosen_data = load_erp_subject_avgref_or_nothing(
        "MMN";
        subject = 1,
        timepoint = 96,
        condition = 3,
    )
    isnothing(chosen_data) && error("No cached avgref case was found for the pipeline illustration.")

    # Reuse rereferenced voltage for display and rereferenced |t| for region scoring.
    display_field = avgref_signal(chosen_data)
    score_field = avgref_abs_t(chosen_data)
    finite_display = Float32[Float32(value) for value in vec(display_field) if isfinite(value)]
    display_limits = if isempty(finite_display)
        (-1f0, 1f0)
    else
        lo, hi = extrema(finite_display)
        m = max(abs(lo), abs(hi))
        m <= 0f0 ? (-1f0, 1f0) : (-m, m)
    end

    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, score_field; labels = chosen_data.labels)
    xg, yg, _, zmask = extract_topoplot_grid(h)
    mask = h.plots[1].mask[]

    # Keep only visible grid points so the survey illustration matches the head mask.
    grid_x = Float32[]
    grid_y = Float32[]
    for i in 1:3:length(xg), j in 1:3:length(yg)
        mask[i, j] > 0 || continue
        push!(grid_x, Float32(xg[i]))
        push!(grid_y, Float32(yg[j]))
    end

    score_rows = region_weights_from_grid(
        xg,
        yg,
        zmask,
        TOPO_REGIONS;
        agg = :mean,
        n_bins = 10,
        binning = :quantile,
        reverse = false,
    )

    raw_scores = Dict(row.label => Float64(row.raw_score) for row in score_rows)
    valid_scores = [score for score in Base.values(raw_scores) if isfinite(score)]
    lo, hi = extrema(valid_scores)

    normalised_scores = Dict(
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

    # Shared styling for the four pipeline stages.
    bg = RGBf(1, 1, 1)
    overlay_black = RGBAf(0, 0, 0, 1)
    blank_cmap = cgrad([:white, :white])
    diverging_cmap = cgrad(:RdBu, 10; categorical = true, rev = true)
    score_cmap = cgrad(:viridis, 10; categorical = true)
    stage_width = 320
    stage_height = 280
    colorbar_height = 68
    arrow_width = 48
    topoplot_kw = (;
        labels = chosen_data.labels,
        clip = false,
        colorrange = display_limits,
        label_text = false,
    )
    blank_topoplot_kw = (; topoplot_kw..., contours = false, colormap = blank_cmap, label_scatter = false)
    signal_topoplot_kw = (; topoplot_kw..., contours = true, colormap = diverging_cmap)
    axis_kw = (;
        aspect = DataAspect(),
        backgroundcolor = bg,
        xlabel = "",
        width = stage_width,
        height = stage_height,
        xautolimitmargin = (0.02, 0.02),
        yautolimitmargin = (0.03, 0.06),
    )
    colorbar_kw = (;
        labelsize = 22,
        ticklabelsize = 15,
        vertical = false,
        width = stage_width - 20,
        labelrotation = 2π,
    )
    region_polys = [
        let
            poly = region_polygon(
                reg;
                template_center = (150.0f0, 150.0f0),
                template_radius = 150.0f0,
                head_center = (0.0f0, -0.08f0),
                head_radius = 1.33f0,
            )
            xs = [p[1] for p in poly]
            ys = [p[2] for p in poly]
            (
                label = reg.label,
                poly = poly,
                center = polygon_centroid(poly),
                xs = vcat(xs, xs[1]),
                ys = vcat(ys, ys[1]),
            )
        end for reg in TOPO_REGIONS
    ]

    let
        make_panel = function(parent, col, title)
            panel = parent[1, col] = GridLayout()
            ax = Axis(panel[1, 1]; axis_kw..., title = title, titlesize = 20, titlealign = :center)
            footer = panel[2, 1] = GridLayout()
            hidedecorations!(ax, label = false)
            hidespines!(ax)
            rowsize!(panel, 1, Fixed(stage_height))
            rowsize!(panel, 2, Fixed(colorbar_height))
            rowgap!(panel, -20)
            panel, ax, footer
        end

        draw_grid_overlay! = function(ax)
            for region in region_polys
                lines!(ax, region.xs, region.ys; color = overlay_black, linewidth = 1.4)
            end
        end

        fig = Figure(
            size = (4 * stage_width + 3 * arrow_width + 120, stage_height + 130),
            backgroundcolor = bg,
            figure_padding = (18, 18, 18, 18),
        )
        grid = fig[1, 1] = GridLayout()
        colgap!(grid, 8)

        topo_panel, topo_ax, topo_footer = make_panel(grid, 1, "1. Topoplot")
        topo_plot = eeg_topoplot!(topo_ax, display_field; signal_topoplot_kw...)
        Colorbar(topo_footer[1, 1], topo_plot; colorbar_kw..., label = "Voltage [µV]")

        for col in (2, 4, 6)
            Label(grid[1, col], "→"; fontsize = 44)
        end

        grid_panel, grid_ax, grid_footer = make_panel(grid, 3, "2. Clickable Grid")
        eeg_topoplot!(grid_ax, display_field; blank_topoplot_kw...)
        draw_grid_overlay!(grid_ax)
        dummy_cmap = cgrad([RGBAf(1, 1, 1, 0), RGBAf(1, 1, 1, 0)])
        Colorbar(
            grid_footer[1, 1];
            colormap = dummy_cmap,
            limits = display_limits,
            ticks = ([-2, -1, 0, 1, 2], ["-2", "-1", "0", "1", "2"]),
            colorbar_kw...,
            label = "Voltage [µV]",
            labelcolor = RGBAf(0, 0, 0, 0),
            ticklabelcolor = RGBAf(0, 0, 0, 0),
            tickcolor = RGBAf(0, 0, 0, 0),
            spinewidth = 0,
        )

        overlay_panel, overlay_ax, overlay_footer = make_panel(grid, 5, "3. Topoplot + Grid")
        overlay_plot = eeg_topoplot!(overlay_ax, display_field; signal_topoplot_kw...)
        draw_grid_overlay!(overlay_ax)
        Colorbar(overlay_footer[1, 1], overlay_plot; colorbar_kw..., label = "Voltage [µV]")

        score_panel, score_ax, score_footer = make_panel(grid, 7, "4. Region Scores")
        eeg_topoplot!(score_ax, display_field; blank_topoplot_kw...)
        for region in region_polys
            score = get(normalised_scores, region.label, NaN)
            bin = isfinite(score) ? clamp(floor(Int, score * 10) + 1, 1, 10) : 1
            poly!(
                score_ax,
                region.poly;
                color = isfinite(score) ? score_cmap[bin] : :white,
                strokecolor = :black,
                strokewidth = 1.2,
            )

            text!(
                score_ax,
                region.center;
                text = isfinite(score) ? string(round(score, digits = 2)) : "",
                align = (:center, :center),
                fontsize = 10,
                color = :black,
            )
        end

        Colorbar(score_footer[1, 1]; colormap = score_cmap, limits = (0.0, 1.0), 
        ticks = (0.0:0.25:1.0, string.(0.0:0.25:1.0)), 
        colorbar_kw..., label = "Normalised SNR [0, 1]")

        for col in (1, 3, 5, 7)
            colsize!(grid, col, Fixed(stage_width))
        end
        for col in (2, 4, 6)
            colsize!(grid, col, Fixed(arrow_width))
        end

        top30_pipeline_illustration_path = joinpath(
            "experiments",
            "figures",
            "example_pipeline_illustration.png",
        )
        mkpath(dirname(top30_pipeline_illustration_path))
        save(top30_pipeline_illustration_path, fig)
        #= for (name, ax) in [
            ("topo_ax", topo_ax),
            ("grid_ax", grid_ax),
            ("overlay_ax", overlay_ax),
            ("score_ax", score_ax),
        ]
            @show name
            @show ax.finallimits[]
            @show ax.scene.px_area[]
        end
 =#
        #fig
    end
end



begin
    chosen_data = load_erp_subject_avgref_or_nothing(
        "MMN";
        subject = 2,
        timepoint = 96,
        condition = 3,
    )
    isnothing(chosen_data) && error("No cached avgref case was found for the MMN subject 2 pipeline illustration.")

    voltage = avgref_signal(chosen_data)
    se = Float64.(chosen_data.se)
    raw_snr = abs.(voltage ./ se)

    finite_voltage = Float32[Float32(value) for value in vec(voltage) if isfinite(value)]
    voltage_limits = if isempty(finite_voltage)
        (-1f0, 1f0)
    else
        lo, hi = extrema(finite_voltage)
        m = max(abs(lo), abs(hi))
        m <= 0f0 ? (-1f0, 1f0) : (-m, m)
    end

    finite_se = Float32[Float32(value) for value in vec(se) if isfinite(value)]
    se_limits = isempty(finite_se) ? (0f0, 1f0) : extrema(finite_se)

    finite_snr = Float32[Float32(value) for value in vec(raw_snr) if isfinite(value)]
    snr_limits = isempty(finite_snr) ? (0f0, 1f0) : (0f0, max(maximum(finite_snr), 1f0))

    bg = RGBf(1, 1, 1)
    diverging_cmap = cgrad(:RdBu, 10; categorical = true, rev = true)
    positive_cmap = cgrad(:viridis, 10; categorical = true)
    snr_cmap = cgrad(:batlow, 10; categorical = true)
    stage_width = 320
    stage_height = 280
    colorbar_height = 68
    sep_width = 48
    panel_limits = (-1.45, 1.45, -1.45, 1.35)

    axis_kw = (;
        aspect = DataAspect(),
        backgroundcolor = bg,
        xlabel = "",
        width = stage_width,
        height = stage_height,
        limits = panel_limits,
    )
    colorbar_kw = (;
        labelsize = 22,
        ticklabelsize = 15,
        vertical = false,
        width = stage_width - 20,
        labelrotation = 2π,
    )

    let
        colorbar_ticks = function(limits)
            lo, hi = Float64.(limits)
            if !isfinite(lo) || !isfinite(hi)
                return ([0.0], ["0.0"])
            elseif lo == hi
                return ([lo], [string(round(lo, digits = 2))])
            end

            ticks = collect(LinRange(lo, hi, 5))
            labels = string.(round.(ticks, digits = 2))
            ticks, labels
        end

        make_panel = function(parent, col, title)
            panel = parent[1, col] = GridLayout()
            ax = Axis(panel[1, 1]; axis_kw..., title = title, titlesize = 20, titlealign = :center)
            footer = panel[2, 1] = GridLayout()
            hidedecorations!(ax, label = false)
            hidespines!(ax)
            rowsize!(panel, 1, Fixed(stage_height))
            rowsize!(panel, 2, Fixed(colorbar_height))
            rowgap!(panel, -20)
            panel, ax, footer
        end

        fig = Figure(
            size = (3 * stage_width + 2 * sep_width + 120, stage_height + 130),
            backgroundcolor = bg,
            figure_padding = (18, 18, 18, 18),
        )
        grid = fig[1, 1] = GridLayout()
        colgap!(grid, 8)

        voltage_panel, voltage_ax, voltage_footer = make_panel(grid, 1, "1. Signal Voltage [µV]")
        voltage_plot = eeg_topoplot!(
            voltage_ax,
            voltage;
            labels = chosen_data.labels,
            clip = false,
            colorrange = voltage_limits,
            label_text = false,
            contours = true,
            colormap = diverging_cmap,
        )
        Colorbar(voltage_footer[1, 1], voltage_plot; colorbar_kw..., 
        ticks = colorbar_ticks(voltage_limits), label = "")

        Label(grid[1, 2], "/"; fontsize = 44)

        se_panel, se_ax, se_footer = make_panel(grid, 3, "2. Standard Error")
        se_plot = eeg_topoplot!(
            se_ax,
            se;
            labels = chosen_data.labels,
            clip = false,
            colorrange = se_limits,
            label_text = false,
            contours = false,
            colormap = positive_cmap,
        )
        Colorbar(se_footer[1, 1], se_plot; colorbar_kw..., 
        ticks = colorbar_ticks(se_limits), label = "")

        Label(grid[1, 4], "→"; fontsize = 44)

        snr_panel, snr_ax, snr_footer = make_panel(grid, 5, "3. Raw SNR")
        snr_plot = eeg_topoplot!(
            snr_ax,
            raw_snr;
            labels = chosen_data.labels,
            clip = false,
            colorrange = snr_limits,
            label_text = false,
            contours = false,
            colormap = snr_cmap,
        )
        Colorbar(snr_footer[1, 1], snr_plot; colorbar_kw..., 
        ticks = colorbar_ticks(snr_limits), label = "")

        for ax in (voltage_ax, se_ax, snr_ax)
            xlims!(ax, panel_limits[1], panel_limits[2])
            ylims!(ax, panel_limits[3], panel_limits[4])
        end

        for col in (1, 3, 5)
            colsize!(grid, col, Fixed(stage_width))
        end
        for col in (2, 4)
            colsize!(grid, col, Fixed(sep_width))
        end

        mmn2_pipeline_path = joinpath(
            "experiments",
            "figures",
            "example_pipeline_mmn2.png",
        )
        mkpath(dirname(mmn2_pipeline_path))
        fig
        save(mmn2_pipeline_path, fig)
    end
end

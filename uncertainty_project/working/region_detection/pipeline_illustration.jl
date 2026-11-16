include("geometry.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("rereferencing.jl")
include("scoring.jl")
include("plotting.jl")

function plot_region_scoring_pipeline(
    task;
    subject,
    timepoint,
    condition,
    regions = TOPO_REGIONS_32,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    stage_width = 340,
    stage_height = 300,
    arrow_width = 52,
    bg = RGBf(0.98, 0.98, 0.98),
)

    subject_data = load_erp_subject_avgref_or_nothing(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
    )
    isnothing(subject_data) &&
        error("Processed avgref CSV is missing for task=$task, subject=$subject, timepoint=$timepoint, condition=$condition.")

    normalise_zero_one(values) = begin
        vals = Float32[Float32(value) for value in vec(values) if isfinite(value)]
        isempty(vals) && return fill(0f0, size(values))

        lo, hi = extrema(vals)
        hi == lo && return fill(0f0, size(values))

        out = similar(values, Float32)
        for idx in eachindex(values)
            value = values[idx]
            out[idx] = isfinite(value) ? clamp(Float32((value - lo) / (hi - lo)), 0f0, 1f0) : Float32(value)
        end
        out
    end

    original_signal = Float64.(subject_data.estimate)
    rereferenced_signal_values = avgref_signal(subject_data)
    se = Float64.(subject_data.se)
    raw_snr = avgref_abs_t(subject_data)
    raw_snr_label = "Raw SNR = |Voltage| / SE"

    topoplot_display_head(h) = region_head_domain_from_plot(h)
    pipeline_head_limits(center, radius; pad_fraction = 0.025f0) =
        topoplot_head_limits(center, radius; pad_fraction = pad_fraction)
    pipeline_head_limits(domain::RegionHeadDomain; pad_fraction = 0.025f0) =
        topoplot_head_limits(domain; pad_fraction = pad_fraction)

    fit_regions_to_display(
        regions,
        display_domain;
        template_center,
        template_radius,
        head_center,
        head_radius,
    ) = begin
        fitted = fit_region_polygons_to_domain(
            regions,
            display_domain;
            template_center = template_center,
            template_radius = template_radius,
            head_center = head_center,
            head_radius = head_radius,
        )
        (; display_head = display_domain, display_polys = fitted.polygons)
    end

    function pipeline_colorrange(values)
        vals = Float32.(filter(isfinite, values))
        isempty(vals) && return Float32.((0, 1))
        if any(<(0), vals)
            p01, p99 = quantile(vals, [0.01, 0.99])
            m = max(abs(p01), abs(p99))
            return Float32.((-m, m))
        else
            return Float32.((minimum(vals), maximum(vals)))
        end
    end

    function pipeline_nonnegative_colorrange(values)
        vals = Float32[Float32(value) for value in vec(values) if isfinite(value)]
        isempty(vals) && return Float32.((0, 1))
        hi = maximum(vals)
        hi <= 0f0 && return Float32.((0, 1))
        Float32.((0, hi))
    end

    raw_snr_limits = pipeline_nonnegative_colorrange(raw_snr)

    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h_score = eeg_topoplot!(tmpax, raw_snr; labels = subject_data.labels)
    display_head = topoplot_display_head(h_score)
    display_limits = pipeline_head_limits(display_head)

    function pipeline_topoplot!(
        slot,
        values;
        labels,
        title,
        colorbar_label,
        colormap,
        contours = true,
        clip = false,
        colorrange = nothing,
        plot_width = stage_width,
        plot_height = stage_height,
        display_limits = nothing,
    )
        colorrange = isnothing(colorrange) ? pipeline_colorrange(values) : Float32.(colorrange)
        ticks = LinRange(colorrange[1], colorrange[2], 5)
        ticklabels = string.(round.(ticks, digits = 2))

        gl = slot[] = GridLayout()
        ax = Axis(
            gl[1, 1];
            aspect = DataAspect(),
            backgroundcolor = bg,
            title = title,
            titlesize = 20,
            xlabel = "",
            width = plot_width,
            height = plot_height,
            xautolimitmargin = (0.02, 0.02),
            yautolimitmargin = (0.03, 0.06),
        )
        h = eeg_topoplot!(
            ax,
            values;
            labels = labels,
            contours = contours,
            clip = clip,
            colormap = colormap,
            colorrange = colorrange,
            label_text = false,
        )
        hidedecorations!(ax, label = false)
        hidespines!(ax)
        rendered_head = topoplot_display_head(h)
        final_limits = isnothing(display_limits) ?
            pipeline_head_limits(rendered_head.center, rendered_head.radius) :
            display_limits
        limits!(ax, final_limits...)

        Colorbar(
            gl[2, 1],
            h;
            label = colorbar_label,
            labelsize = 22,
            ticklabelsize = 15,
            ticks = (ticks, ticklabels),
            vertical = false,
            width = plot_width - 20,
            labelrotation = 2π,
        )
        colsize!(gl, 1, Fixed(plot_width))
        rowsize!(gl, 1, Fixed(plot_height))
        rowsize!(gl, 2, Fixed(68))
        rowgap!(gl, -20)
        return gl, ax, h
    end

    function pipeline_region_panel!(
        slot,
        weights;
        title,
        colorbar_label,
        palette,
        topoplot_labels,
        show_labels = false,
        fontsize = 16,
        fontcolor = :black,
        missing_color = :white,
        strokecolor = :black,
        strokewidth = 1.2,
        colorbar_limits = nothing,
        colorbar_ticks = nothing,
        colorbar_colormap = nothing,
        region_text = nothing,
        display_head = nothing,
        display_limits = nothing,
    )
        gl = slot[] = GridLayout()
        ax = Axis(
            gl[1, 1];
            aspect = DataAspect(),
            backgroundcolor = bg,
            title = title,
            titlesize = 20,
            xlabel = "",
            width = stage_width,
            height = stage_height,
            xautolimitmargin = (0.02, 0.02),
            yautolimitmargin = (0.03, 0.06),
        )
        hidedecorations!(ax, label = false)
        hidespines!(ax)
        isnothing(display_head) && error("pipeline_region_panel! needs `display_head`.")
        isnothing(display_limits) && error("pipeline_region_panel! needs `display_limits`.")
        limits!(ax, display_limits...)

        fitted = fit_regions_to_display(
            regions,
            display_head;
            template_center = template_center,
            template_radius = template_radius,
            head_center = head_center,
            head_radius = head_radius,
        )

        for (idx, reg) in enumerate(regions)
            poly = fitted.display_polys[idx]
            w = haskey(weights, reg.label) ? weights[reg.label] :
                haskey(weights, Symbol(reg.label)) ? weights[Symbol(reg.label)] : 0
            poly!(
                ax,
                poly;
                color = get(palette, w, missing_color),
                strokecolor = strokecolor,
                strokewidth = strokewidth,
            )
        end

        positions = TopoPlots.labels2positions(topoplot_labels)
        dummy = collect(LinRange(0f0, 1f0, length(positions)))
        transparent_cmap = cgrad([RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0)])
        eeg_topoplot!(
            ax,
            dummy;
            labels = topoplot_labels,
            positions = positions,
            contours = false,
            clip = false,
            colormap = transparent_cmap,
            colorrange = (0f0, 1f0),
            label_scatter = false,
            label_text = false,
        )
        limits!(ax, display_limits...)

        if !isnothing(region_text)
            for (idx, reg) in enumerate(regions)
                c = polygon_centroid(fitted.display_polys[idx])
                text!(
                    ax,
                    c;
                    text = region_text[reg.label],
                    align = (:center, :center),
                    fontsize = 10,
                    color = :black,
                )
            end
        end

        if isnothing(colorbar_colormap)
            colorbar_colormap = cgrad([palette[i] for i in sort(collect(keys(palette)))]; categorical = true)
        end
        Colorbar(
            gl[2, 1];
            colormap = colorbar_colormap,
            limits = colorbar_limits,
            ticks = colorbar_ticks,
            label = colorbar_label,
            labelsize = 22,
            ticklabelsize = 15,
            width = stage_width - 20,
            vertical = false,
            labelrotation = 2π,
        )
        colsize!(gl, 1, Fixed(stage_width))
        rowsize!(gl, 1, Fixed(stage_height))
        rowsize!(gl, 2, Fixed(68))
        rowgap!(gl, -20)
        return gl, ax
    end

    top_row_width = 4 * stage_width + 3 * arrow_width
    bottom_row_width = 3 * stage_width + 2 * arrow_width
    row_width = max(top_row_width, bottom_row_width)

    f = Figure(
        size = (row_width + 120, 980),
        backgroundcolor = bg,
        figure_padding = (14, 14, 10, 10),
    )
    case_id = "$(task)_$(subject)"

    Label(
        f[1, 1],
        "$case_id | $(timepoint) ms | condition $condition";
        fontsize = 30,
        font = :bold,
    )

    top_gl = f[2, 1] = GridLayout()

    pipeline_topoplot!(
        top_gl[1, 1],
        original_signal;
        labels = subject_data.labels,
        title = "1. Original Signal",
        colorbar_label = "Voltage [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        contours = true,
        clip = false,
        display_limits = display_limits,
    )

    Label(top_gl[1, 2], "→"; fontsize = 46)

    pipeline_topoplot!(
        top_gl[1, 3],
        rereferenced_signal_values;
        labels = subject_data.labels,
        title = "2. Rereferenced Signal",
        colorbar_label = "Rereferenced [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        contours = true,
        clip = false,
        display_limits = display_limits,
    )

    Label(top_gl[1, 4], "+"; fontsize = 46)

    pipeline_topoplot!(
        top_gl[1, 5],
        se;
        labels = subject_data.labels,
        title = "3. SE Topoplot",
        colorbar_label = "SE",
        colormap = cgrad(:viridis, 10; categorical = true),
        contours = true,
        clip = false,
        display_limits = display_limits,
    )

    Label(top_gl[1, 6], "→"; fontsize = 46)

    pipeline_topoplot!(
        top_gl[1, 7],
        raw_snr;
        labels = subject_data.labels,
        title = "4. Raw SNR",
        colorbar_label = raw_snr_label,
        colormap = cgrad(:batlow, 10; categorical = true),
        contours = true,
        clip = false,
        colorrange = raw_snr_limits,
        display_limits = display_limits,
    )
    xg, yg, _, Zmask = extract_topoplot_grid(h_score)
    rows_t = region_weights_from_grid(
        xg,
        yg,
        Zmask,
        regions;
        agg = :mean,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        mask = h_score.plots[1].mask[],
        topoplot_domain = display_head,
        n_bins = 8,
        binning = :quantile,
        reverse = false,
    )
    raw_scores = Dict(r.label => r.raw_score for r in rows_t)
    raw_valid = filter(isfinite, collect(values(raw_scores)))
    raw_lo = minimum(raw_valid)
    raw_hi = maximum(raw_valid)
    raw_score_limits = raw_hi == raw_lo ? (raw_lo - 0.5f0, raw_hi + 0.5f0) : (raw_lo, raw_hi)
    raw_score_cmap = cgrad(:batlow, 10; categorical = true)
    raw_score_palette = Dict(i => raw_score_cmap[i] for i in 1:10)
    raw_score_bins = Dict(
        label => (
            raw_hi == raw_lo ? 10 :
            clamp(floor(Int, (score - raw_lo) / (raw_hi - raw_lo) * 10) + 1, 1, 10)
        ) for (label, score) in pairs(raw_scores)
    )

    normalised_score_labels = [row.label for row in rows_t]
    normalised_score_values = normalise_zero_one(Float64[row.raw_score for row in rows_t])
    normalised_scores = Dict(
        normalised_score_labels[idx] => Float64(normalised_score_values[idx])
        for idx in eachindex(normalised_score_labels)
    )
    normalised_score_palette = Dict(i => cgrad(:viridis, 10; categorical = true)[i] for i in 1:10)
    normalised_score_bins = Dict(
        label => clamp(floor(Int, score * 10) + 1, 1, 10)
        for (label, score) in pairs(normalised_scores)
    )
    bottom_gl = f[3, 1] = GridLayout()

    _, ax_overlay, _ = pipeline_topoplot!(
        bottom_gl[1, 1],
        raw_snr;
        labels = subject_data.labels,
        title = "5. Raw SNR + Regions",
        colorbar_label = raw_snr_label,
        colormap = cgrad(:batlow, 10; categorical = true),
        contours = true,
        clip = false,
        colorrange = raw_snr_limits,
        display_limits = display_limits,
    )
    fitted_overlay = fit_regions_to_display(
        regions,
        display_head;
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
    )
    for (idx, reg) in enumerate(regions)
        poly = fitted_overlay.display_polys[idx]
        lines!(
            ax_overlay,
            [p[1] for p in poly] |> xs -> vcat(xs, first(xs)),
            [p[2] for p in poly] |> ys -> vcat(ys, first(ys));
            color = :black,
            linewidth = 1.5,
        )
        c = polygon_centroid(poly)
        text!(
            ax_overlay,
            c;
            text = reg.label,
            align = (:center, :center),
            fontsize = 15,
            color = :red,
        )
    end

    Label(bottom_gl[1, 2], "→"; fontsize = 46)
    raw_score_text = Dict(label => string(round(raw_scores[label], digits = 2)) for label in keys(raw_scores))
    raw_score_ticks = LinRange(raw_score_limits[1], raw_score_limits[2], 5)
    raw_score_gl = bottom_gl[1, 3]
    pipeline_region_panel!(
        raw_score_gl,
        raw_score_bins;
        title = "6. Raw Region Scores",
        colorbar_label = "Raw score",
        palette = raw_score_palette,
        topoplot_labels = subject_data.labels,
        show_labels = false,
        missing_color = :white,
        strokecolor = :black,
        strokewidth = 1.1,
        colorbar_limits = raw_score_limits,
        colorbar_ticks = (raw_score_ticks, string.(round.(raw_score_ticks, digits = 2))),
        colorbar_colormap = raw_score_cmap,
        region_text = raw_score_text,
        display_head = display_head,
        display_limits = display_limits,
    )

    Label(bottom_gl[1, 4], "→"; fontsize = 46)

    normalised_score_ticks = (0.0:0.25:1.0, string.(0.0:0.25:1.0))
    normalised_score_text = Dict(
        label => string(round(normalised_scores[label], digits = 2))
        for label in keys(normalised_scores)
    )
    normalised_score_gl = bottom_gl[1, 5]
    pipeline_region_panel!(
        normalised_score_gl,
        normalised_score_bins;
        title = "7. Normalised Scores",
        colorbar_label = "Normalised score [0, 1]",
        palette = normalised_score_palette,
        topoplot_labels = subject_data.labels,
        show_labels = false,
        missing_color = :white,
        strokecolor = :black,
        strokewidth = 1.1,
        colorbar_limits = (0.0, 1.0),
        colorbar_ticks = normalised_score_ticks,
        colorbar_colormap = cgrad([normalised_score_palette[i] for i in 1:10]; categorical = true),
        region_text = normalised_score_text,
        display_head = display_head,
        display_limits = display_limits,
    )

    colsize!(top_gl, 1, Fixed(stage_width))
    colsize!(top_gl, 2, Fixed(arrow_width))
    colsize!(top_gl, 3, Fixed(stage_width))
    colsize!(top_gl, 4, Fixed(arrow_width))
    colsize!(top_gl, 5, Fixed(stage_width))
    colsize!(top_gl, 6, Fixed(arrow_width))
    colsize!(top_gl, 7, Fixed(stage_width))

    colsize!(bottom_gl, 1, Fixed(stage_width))
    colsize!(bottom_gl, 2, Fixed(arrow_width))
    colsize!(bottom_gl, 3, Fixed(stage_width))
    colsize!(bottom_gl, 4, Fixed(arrow_width))
    colsize!(bottom_gl, 5, Fixed(stage_width))

    colsize!(f.layout, 1, Fixed(row_width))
    rowsize!(f.layout, 1, Fixed(68))
    rowsize!(f.layout, 2, Fixed(stage_height + 88))
    rowsize!(f.layout, 3, Fixed(stage_height + 88))
    rowgap!(f.layout, 1, 18)
    rowgap!(f.layout, 2, 28)
    colgap!(top_gl, 8)
    colgap!(bottom_gl, 8)

    f
end

#= plot_region_scoring_pipeline(
           "N170";
           subject = 26,
           timepoint = 105,
           condition = 2,
       ) =#

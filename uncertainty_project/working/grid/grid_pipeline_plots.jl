# Helpers for the step-by-step pipeline figure:
# data loading -> topoplot display domain -> region scoring -> rendered panels.

function extract_topoplot_grid_local(h)
    tp = h.plots[1]
    xg = Float32.(tp.xg[])
    yg = Float32.(tp.yg[])
    z = Float32.(tp.data_interpolated[])
    mask = tp.mask[]
    zmask = mask .* z
    return xg, yg, z, zmask
end

function finite_range(values; nonnegative = false)
    vals = Float32[Float32(v) for v in vec(values) if isfinite(v)]
    isempty(vals) && return Float32.((0, 1))
    if nonnegative || all(v -> v >= 0, vals)
        hi = maximum(vals)
        return hi <= 0 ? Float32.((0, 1)) : Float32.((0, hi))
    end

    p01, p99 = quantile(vals, [0.01, 0.99])
    m = max(abs(p01), abs(p99))
    return Float32.((-m, m))
end

function normalise_dict(score_dict::Dict{String,<:Real})
    valid = Float64[v for v in Base.values(score_dict) if isfinite(v)]
    isempty(valid) && return Dict(key => 0.0 for key in keys(score_dict))
    lo, hi = extrema(valid)
    if hi == lo
        return Dict(key => 0.0 for key in keys(score_dict))
    end
    return Dict(
        key => begin
            value = Float64(score_dict[key])
            isfinite(value) ? clamp((value - lo) / (hi - lo), 0.0, 1.0) : NaN
        end for key in keys(score_dict)
    )
end

function pipeline_head_outline_parts(center::Point2f, radius)
    cx, cy = center
    diameter = 2radius
    θ = range(0, 2π; length = 400)
    circle = Point2f[pt(cx + radius * cos(t), cy + radius * sin(t)) for t in θ]
    nose = (Point2f[(-0.05, 0.5), (0.0, 0.55), (0.05, 0.5)] .* diameter) .+ (center,)
    ear = (Point2f[
        (0.497, 0.0555), (0.51, 0.0775), (0.518, 0.0783), (0.5299, 0.0746), (0.5419, 0.0555),
        (0.54, -0.0055), (0.547, -0.0932), (0.532, -0.1313), (0.51, -0.1384), (0.489, -0.1199),
    ] .* diameter)
    left_ear = ear .+ center
    right_ear = (ear .* Point2f(-1, 1)) .+ (center,)
    return (; circle, nose, left_ear, right_ear)
end

function pipeline_head_limits(center::Point2f, radius; pad_fraction = 0.025f0)
    parts = pipeline_head_outline_parts(center, radius)
    pts = vcat(parts.circle, parts.nose, parts.left_ear, parts.right_ear)
    xmin = minimum(p[1] for p in pts)
    xmax = maximum(p[1] for p in pts)
    ymin = minimum(p[2] for p in pts)
    ymax = maximum(p[2] for p in pts)
    xpad = (xmax - xmin) * pad_fraction
    ypad = (ymax - ymin) * pad_fraction
    return (xmin - xpad, xmax + xpad, ymin - ypad, ymax + ypad)
end

pipeline_head_limits(domain::TopoplotDomain; pad_fraction = 0.025f0) =
    pipeline_head_limits(domain.center, domain_mask_radius(domain); pad_fraction = pad_fraction)

function draw_pipeline_head_outline!(
    ax,
    center::Point2f,
    radius;
    color = :black,
    linewidth = 1.6,
)
    parts = pipeline_head_outline_parts(center, radius)
    xs = Float32[p[1] for p in parts.circle]
    ys = Float32[p[2] for p in parts.circle]
    lines!(ax, xs, ys; color = color, linewidth = linewidth)
    lines!(ax, parts.nose; color = color, linewidth = linewidth)
    lines!(ax, parts.left_ear; color = color, linewidth = linewidth)
    lines!(ax, parts.right_ear; color = color, linewidth = linewidth)
    return ax
end

function pipeline_panel_axis(slot; title, width, height, backgroundcolor = :white)
    gl = slot[] = GridLayout()
    ax = Axis(
        gl[1, 1];
        aspect = DataAspect(),
        backgroundcolor = backgroundcolor,
        title = title,
        titlesize = 18,
        width = width,
        height = height,
        xlabel = "",
        xautolimitmargin = (0.02, 0.02),
        yautolimitmargin = (0.03, 0.06),
    )
    hidedecorations!(ax, label = false)
    hidespines!(ax)
    return gl, ax
end

function pipeline_topoplot_panel!(
    slot,
    values;
    labels,
    title,
    colorbar_label,
    colormap,
    colorrange,
    width,
    height,
    contours = true,
    label_scatter = false,
    label_text = false,
    clip = false,
    show_colorbar = true,
    colorbar_ticks = nothing,
)
    gl, ax = pipeline_panel_axis(slot; title, width, height)
    h = eeg_topoplot!(
        ax,
        values;
        labels = labels,
        contours = contours,
        clip = clip,
        colormap = colormap,
        colorrange = colorrange,
        label_text = label_text,
        label_scatter = label_scatter,
    )
    if show_colorbar
        ticks = isnothing(colorbar_ticks) ? LinRange(colorrange[1], colorrange[2], 5) : colorbar_ticks
        tick_spec = isnothing(colorbar_ticks) ? (ticks, string.(round.(ticks, digits = 2))) : colorbar_ticks
        Colorbar(
            gl[2, 1],
            h;
            label = colorbar_label,
            labelsize = 18,
            ticklabelsize = 12,
            ticks = tick_spec,
            vertical = false,
            width = width - 24,
            labelrotation = 2π,
        )
    else
        Label(gl[2, 1], " "; color = RGBAf(0, 0, 0, 0))
    end
    rowsize!(gl, 1, Fixed(height))
    rowsize!(gl, 2, Fixed(62))
    rowgap!(gl, -16)
    return gl, ax, h
end

function pipeline_region_panel!(
    slot,
    layout::RegionLayout64,
    cfg::RegionGrid64Config;
    title,
    region_colors,
    colorbar_label,
    colorbar_colormap,
    colorbar_limits,
    colorbar_ticks,
    width,
    height,
    show_region_labels = false,
    template_space = false,
    show_colorbar = true,
    background_labels = nothing,
    background_domain = nothing,
    show_electrodes = false,
)
    gl, ax = pipeline_panel_axis(slot; title, width, height)

    if template_space
        limits!(ax, 0, cfg.canvas_size[1], cfg.canvas_size[2], 0)
        for region in layout.regions
            poly = parse_region_polygon(
                region.points;
                template_center = cfg.template_center,
                template_radius = cfg.template_radius,
                head_center = cfg.parser_head_center,
                head_radius = cfg.parser_head_radius,
            )
            poly!(
                ax,
                poly;
                color = get(region_colors, region.label, :white),
                strokecolor = :black,
                strokewidth = cfg.stroke_width,
            )
            if show_region_labels
                text!(
                    ax,
                    region.template_center;
                    text = region.label,
                    align = (:center, :center),
                    fontsize = 7,
                    color = :black,
                )
            end
        end
    else
        if !isnothing(background_domain)
            limits!(ax, pipeline_head_limits(background_domain)...)
        else
            limits!(ax, preview_limits(layout.domain, cfg)...)
        end

        display_center = layout.domain.center
        display_radius = domain_mask_radius(layout.domain)
        display_polys = [region.polygon for region in layout.regions]
        if !isnothing(background_domain)
            display_center = background_domain.center
            display_radius = domain_mask_radius(background_domain)
            display_polys = [
                map_polygon_between_domains(region.polygon, layout.domain, background_domain)
                for region in layout.regions
            ]
        end
        for (region, poly) in zip(layout.regions, display_polys)
            poly!(
                ax,
                poly;
                color = get(region_colors, region.label, :white),
                strokecolor = :black,
                strokewidth = cfg.stroke_width,
            )
            if show_region_labels
                text!(
                    ax,
                    polygon_centroid(poly);
                    text = region.label,
                    align = (:center, :center),
                    fontsize = 7,
                    color = :black,
                )
            end
        end
        if isnothing(background_labels)
            xs = Float32[p[1] for p in layout.domain.polygon]
            ys = Float32[p[2] for p in layout.domain.polygon]
            lines!(ax, vcat(xs, first(xs)), vcat(ys, first(ys)); color = :black, linewidth = cfg.outline_width)
        else
            draw_pipeline_head_outline!(ax, display_center, display_radius; linewidth = cfg.outline_width)
            show_electrodes && overlay_electrode_layout!(ax, background_labels)
        end
    end

    if show_colorbar
        Colorbar(
            gl[2, 1];
            colormap = colorbar_colormap,
            limits = colorbar_limits,
            ticks = colorbar_ticks,
            label = colorbar_label,
            labelsize = 18,
            ticklabelsize = 12,
            vertical = false,
            width = width - 24,
            labelrotation = 2π,
        )
    else
        Label(gl[2, 1], " "; color = RGBAf(0, 0, 0, 0))
    end
    rowsize!(gl, 1, Fixed(height))
    rowsize!(gl, 2, Fixed(62))
    rowgap!(gl, -16)
    return gl, ax
end

# Build one named tuple with the precomputed plotting inputs
# (signal/SNR values, ranges, domains, raw scores, normalized colors)
# so the panel figure and any score checks read the exact same data.
function pipeline_region_score_payload(layout::RegionLayout64, cfg::RegionGrid64Config)
    subject_data = load_grid_avgref_case_or_nothing(cfg)
    isnothing(subject_data) && error(
        "Missing avgref case for pipeline figure: task=$(cfg.pipeline_task), subject=$(cfg.pipeline_subject), " *
        "timepoint=$(cfg.pipeline_timepoint), condition=$(cfg.pipeline_condition).",
    )

    signal = subject_data.estimate_avgref
    snr = subject_data.abs_t_avgref
    signal_range = finite_range(signal)
    snr_range = finite_range(snr; nonnegative = true)
    snr_cmap = cgrad(:batlow, 10; categorical = true)
    tmpfig = Figure(size = (10, 10))
    tmpax = Axis(tmpfig[1, 1])
    h_score = eeg_topoplot!(tmpax, snr; labels = subject_data.labels)
    xg, yg, _, zmask = extract_topoplot_grid_local(h_score)
    grid_mask = BitMatrix(h_score.plots[1].mask[])
    score_domain = region_head_domain_from_plot(h_score)
    display_domain = topoplot_domain_from_plot(h_score, cfg)
    shared_pipeline_limits = pipeline_head_limits(display_domain)
    score_regions = [(label = region.label, points = region.points) for region in layout.regions]

    score_rows = region_weights_from_grid(
        xg,
        yg,
        zmask,
        score_regions;
        agg = :mean,
        template_center = cfg.template_center,
        template_radius = cfg.template_radius,
        head_center = cfg.parser_head_center,
        head_radius = cfg.parser_head_radius,
        mask = grid_mask,
        topoplot_domain = score_domain,
        n_bins = cfg.pipeline_n_bins,
        binning = :quantile,
        reverse = false,
    )

    raw_scores = Dict(String(row.label) => Float64(row.raw_score) for row in score_rows)
    raw_scores_norm = normalise_dict(raw_scores)
    score_cmap = cgrad(:viridis)
    region_colors_norm = Dict(
        label => (isfinite(raw_scores_norm[label]) ? get(score_cmap, raw_scores_norm[label]) : RGBAf(1, 1, 1, 1))
        for label in keys(raw_scores_norm)
    )

    (
        ;
        labels = subject_data.labels,
        signal,
        snr,
        signal_range,
        snr_range,
        snr_cmap,
        raw_scores,
        display_domain,
        shared_pipeline_limits,
        score_cmap,
        region_colors_norm,
    )
end

function pipeline_case_figure(layout::RegionLayout64, cfg::RegionGrid64Config)
    payload = pipeline_region_score_payload(layout, cfg)

    region_colors_grid = Dict(region.label => RGBAf(1, 1, 1, 0) for region in layout.regions)
    region_colors_overlay = Dict(region.label => RGBAf(1, 1, 1, 0) for region in layout.regions)

    w = cfg.pipeline_stage_width
    h = cfg.pipeline_stage_height
    bg = RGBf(1, 1, 1)
    blank_cmap = cgrad([:white, :white])
    signal_cmap = cgrad(:RdBu, 10; categorical = true, rev = true)
    fig = Figure(size = (3w + 150, 2h + 290), backgroundcolor = bg, figure_padding = (18, 18, 30, 18))

    Label(
        fig[1, 1],
        "Task 2 pipeline with 64-region grid | $(cfg.pipeline_task)_$(cfg.pipeline_subject) | $(cfg.pipeline_timepoint) ms | cond $(cfg.pipeline_condition)";
        fontsize = 22,
        font = :bold,
    )

    top_gl = fig[2, 1] = GridLayout()
    _, ax_signal, _ = pipeline_topoplot_panel!(
        top_gl[1, 1],
        payload.signal;
        labels = payload.labels,
        title = "1. Signal [uV]",
        colorbar_label = "",
        colormap = signal_cmap,
        colorrange = payload.signal_range,
        width = w,
        height = h,
        contours = true,
    )
    _, ax_electrodes, _ = pipeline_topoplot_panel!(
        top_gl[1, 3],
        payload.signal;
        labels = payload.labels,
        title = "2. Electrode layout",
        colorbar_label = "",
        colormap = blank_cmap,
        colorrange = payload.signal_range,
        width = w,
        height = h,
        contours = false,
        show_colorbar = false,
    )
    overlay_electrode_layout!(ax_electrodes, payload.labels)
    limits!(ax_signal, payload.shared_pipeline_limits...)
    limits!(ax_electrodes, payload.shared_pipeline_limits...)
    pipeline_region_panel!(
        top_gl[1, 5],
        layout,
        cfg;
        title = "3. New 64 grid",
        region_colors = region_colors_grid,
        colorbar_label = "",
        colorbar_colormap = blank_cmap,
        colorbar_limits = (0.0, 1.0),
        colorbar_ticks = nothing,
        width = w,
        height = h,
        show_region_labels = false,
        template_space = false,
        show_colorbar = false,
        background_labels = payload.labels,
        background_domain = payload.display_domain,
    )

    bottom_gl = fig[3, 1] = GridLayout()
    pipeline_region_panel!(
        bottom_gl[1, 1],
        layout,
        cfg;
        title = "4. Electrode + grid",
        region_colors = region_colors_overlay,
        colorbar_label = "",
        colorbar_colormap = blank_cmap,
        colorbar_limits = (0.0, 1.0),
        colorbar_ticks = nothing,
        width = w,
        height = h,
        show_region_labels = false,
        template_space = false,
        show_colorbar = false,
        background_labels = payload.labels,
        background_domain = payload.display_domain,
        show_electrodes = true,
    )
    _, ax_snr, _ = pipeline_topoplot_panel!(
        bottom_gl[1, 3],
        payload.snr;
        labels = payload.labels,
        title = "5. SNR |t|",
        colorbar_label = "",
        colormap = payload.snr_cmap,
        colorrange = payload.snr_range,
        width = w,
        height = h,
        contours = true,
    )
    limits!(ax_snr, payload.shared_pipeline_limits...)
    score_ticks = collect(0.0:0.25:1.0)
    pipeline_region_panel!(
        bottom_gl[1, 5],
        layout,
        cfg;
        title = "6. Normalised SNR [0,1]",
        region_colors = payload.region_colors_norm,
        colorbar_label = "",
        colorbar_colormap = payload.score_cmap,
        colorbar_limits = (0.0, 1.0),
        colorbar_ticks = (score_ticks, string.(round.(score_ticks, digits = 2))),
        width = w,
        height = h,
        show_region_labels = false,
        template_space = false,
        show_colorbar = true,
        background_labels = payload.labels,
        background_domain = payload.display_domain,
    )

    colsize!(top_gl, 1, Fixed(w))
    colsize!(top_gl, 3, Fixed(w))
    colsize!(top_gl, 5, Fixed(w))
    colgap!(top_gl, 14)

    colsize!(bottom_gl, 1, Fixed(w))
    colsize!(bottom_gl, 3, Fixed(w))
    colsize!(bottom_gl, 5, Fixed(w))
    colgap!(bottom_gl, 14)

    rowsize!(fig.layout, 1, Fixed(80))
    rowsize!(fig.layout, 2, Fixed(h + 72))
    rowsize!(fig.layout, 3, Fixed(h + 72))
    rowgap!(fig.layout, 1, 18)
    rowgap!(fig.layout, 2, 20)

    return fig
end

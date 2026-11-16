@isdefined(load_erp_subject_avgref_or_nothing) || include("rereferencing.jl")

function _draw_head_outline!(
    ax;
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.0f0,
    color = :black,
    linewidth = 2.5,
)
    cx, cy = head_center

    θ = range(0, 2π; length = 400)
    lines!(
        ax,
        cx .+ head_radius .* cos.(θ),
        cy .+ head_radius .* sin.(θ);
        color = color,
        linewidth = linewidth,
    )

    lines!(
        ax,
        cx .+ head_radius .* Float32[-0.14, 0.0, 0.14],
        cy .+ head_radius .* Float32[0.98, 1.12, 0.98];
        color = color,
        linewidth = linewidth,
    )

    lines!(
        ax,
        cx .+ head_radius .* Float32[-1.00, -1.08, -1.10, -1.08, -1.00],
        cy .+ head_radius .* Float32[0.18, 0.10, 0.00, -0.10, -0.18];
        color = color,
        linewidth = linewidth,
    )

    lines!(
        ax,
        cx .+ head_radius .* Float32[1.00, 1.08, 1.10, 1.08, 1.00],
        cy .+ head_radius .* Float32[0.18, 0.10, 0.00, -0.10, -0.18];
        color = color,
        linewidth = linewidth,
    )

    return ax
end

function _region_weight_topoplot_config(
    ;
    regions = TOPO_REGIONS_32,
    palette = Dict(i => cgrad(:viridis, 4; categorical = true)[i] for i in 1:4),
    missing_color = :white,
    show_labels = false,
    label_mode = :weight,
    outline_center = (0.0f0, -0.08f0),
    region_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    strokecolor = :black,
    strokewidth = 1.2,
    fontsize = 16,
    fontcolor = :black,
    topoplot_labels = nothing,
    topoplot_positions = nothing,
    topoplot_domain = nothing,
    topoplot_plot = nothing,
    size = (700, 740),
)
    (; regions, palette, missing_color, show_labels, label_mode, outline_center, region_center,
     head_radius, template_center, template_radius, strokecolor, strokewidth, fontsize,
     fontcolor, topoplot_labels, topoplot_positions, topoplot_domain, topoplot_plot, size)
end

plot_region_weight_topoplot(weights; kwargs...) = plot_region_weight_topoplot!(Figure(), weights; kwargs...)

function plot_region_weight_topoplot!(f::Union{GridPosition, GridLayout, Figure}, weights; kwargs...)
    cfg = _region_weight_topoplot_config(; kwargs...)
    slot = f isa GridPosition ? f : f[1, 1]
    ax = Axis(slot; aspect = DataAspect(), width = cfg.size[1], height = cfg.size[2])
    hidedecorations!(ax)
    hidespines!(ax)

    pad = 0.2f0
    limits!(
        ax,
        cfg.outline_center[1] - cfg.head_radius - pad,
        cfg.outline_center[1] + cfg.head_radius + pad,
        cfg.outline_center[2] - cfg.head_radius - pad,
        cfg.outline_center[2] + cfg.head_radius + pad,
    )

    plot_region_weight_topoplot!(ax, weights; kwargs...)
    return Makie.get_figure(slot), ax
end

function plot_region_weight_topoplot!(ax::Axis, weights; kwargs...)
    cfg = _region_weight_topoplot_config(; kwargs...)
    domain = isnothing(cfg.topoplot_domain) ? (
        isnothing(cfg.topoplot_plot) ? nothing : region_head_domain_from_plot(cfg.topoplot_plot)
    ) : cfg.topoplot_domain
    head_drawn = !isnothing(cfg.topoplot_plot)

    if isnothing(domain) && (!isnothing(cfg.topoplot_labels) || !isnothing(cfg.topoplot_positions))
        positions = isnothing(cfg.topoplot_positions) ?
            TopoPlots.labels2positions(cfg.topoplot_labels) : cfg.topoplot_positions
        n = length(positions)
        dummy = collect(LinRange(0f0, 1f0, n))
        transparent_cmap = cgrad([RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0)])
        h = eeg_topoplot!(
            ax,
            dummy;
            labels = cfg.topoplot_labels,
            positions = positions,
            contours = false,
            clip = false,
            colormap = transparent_cmap,
            colorrange = (0f0, 1f0),
            label_scatter = false,
            label_text = false,
        )
        domain = region_head_domain_from_plot(h)
        head_drawn = true
    end

    polys = isnothing(domain) ? [
        region_polygon(
            reg;
            template_center = cfg.template_center,
            template_radius = cfg.template_radius,
            head_center = cfg.region_center,
            head_radius = cfg.head_radius,
        ) for reg in cfg.regions
    ] : fit_region_polygons_to_domain(
        cfg.regions,
        domain;
        template_center = cfg.template_center,
        template_radius = cfg.template_radius,
        head_center = cfg.region_center,
        head_radius = cfg.head_radius,
    ).polygons

    !isnothing(domain) && limits!(ax, topoplot_head_limits(domain)...)

    for (reg, poly) in zip(cfg.regions, polys)
        w = haskey(weights, reg.label) ? weights[reg.label] :
            haskey(weights, Symbol(reg.label)) ? weights[Symbol(reg.label)] : 0

        poly!(
            ax,
            poly;
            color = get(cfg.palette, w, cfg.missing_color),
            strokecolor = cfg.strokecolor,
            strokewidth = cfg.strokewidth,
        )

        if cfg.show_labels
            c = polygon_centroid(poly)
            txt = cfg.label_mode == :weight ? string(w) :
                cfg.label_mode == :region ? reg.label : "$(reg.label)\n$w"
            text!(
                ax,
                c;
                text = txt,
                align = (:center, :center),
                fontsize = cfg.fontsize,
                color = cfg.fontcolor,
            )
        end
    end

    if isnothing(domain)
        _draw_head_outline!(ax; head_center = cfg.outline_center, head_radius = cfg.head_radius)
    elseif !head_drawn
        _draw_head_outline!(ax; head_center = (domain.center[1], domain.center[2]), head_radius = domain.radius)
    end
    return ax
end

function triple_SNR(test; sew = 3)
    f = Figure(size = (600, 500))
    signal = avgref_signal(test)
    snr = avgref_abs_t(test)

    lims_est = begin
        p01, p99 = quantile(signal, [0.01, 0.99])
        m = max(abs(p01), abs(p99))
        Float32.((-m, m))
    end

    lims_se = begin
        p01, p99 = quantile(test.se .* sew, [0.01, 0.99])
        Float32.((p01, p99))
    end

    plot_topoplot!(
        f[1, 1],
        signal;
        labels = test.labels,
        axis = (; title = "Signal: Voltage", titlesize = 18, xlabel = ""),
        visual = (; colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true), colorrange = lims_est, contours = false),
        colorbar = (; position = :bottom, width = 180, vertical = false, label = ""),
        layout = (; use_colorbar = true),
    )

    plot_topoplot!(
        f[2, 1],
        test.se .* sew;
        labels = test.labels,
        axis = (; title = "Noise: Standard Error", titlesize = 18, xlabel = ""),
        visual = (; colormap = cgrad(:viridis, 10; categorical = true, rev = true), contours = false, colorrange = lims_se),
        colorbar = (; position = :bottom, width = 180, vertical = false, label = ""),
        layout = (; use_colorbar = true),
    )

    plot_topoplot!(
        f[1:2, 2],
        snr ./ sew;
        labels = test.labels,
        axis = (; title = "Signal-to-Noise Ratio", titlesize = 18, xlabel = ""),
        visual = (; colormap = cgrad(:batlow, 10; categorical = true), contours = false),
        colorbar = (; position = :bottom, width = 180, vertical = false, label = ""),
        layout = (; use_colorbar = true),
    )

    return f
end

_subject_abs_snr(test) = avgref_abs_t(test)

function make_region_key(
    configs_tasks;
    n_bins = 4,
    agg = :mean,
    binning = :quantile,
    score_transform = identity,
    reverse = false,
)
    rows = NamedTuple[]

    for cfg in configs_tasks
        for subj in cfg.subjects
            test = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subj,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )
            isnothing(test) && continue
            snr = _subject_abs_snr(test)
            tmpfig = Figure()
            tmpax = Axis(tmpfig[1, 1])
            h = eeg_topoplot!(tmpax, snr; labels = test.labels)
            xg, yg, Z, Zmask = extract_topoplot_grid(h)
            domain = region_head_domain_from_plot(h)

            rw = region_weights_from_grid(
                xg,
                yg,
                score_transform.(Zmask),
                TOPO_REGIONS;
                agg = agg,
                mask = h.plots[1].mask[],
                topoplot_domain = domain,
                n_bins = n_bins,
                binning = binning,
                reverse = reverse,
            )

            push!(
                rows,
                (
                    stimulus = "$(cfg.task)_$(subj)",
                    weights = Dict(String(x.label) => x.weight for x in rw),
                ),
            )
        end
    end

    return rows
end

region_key_dict(rows) = Dict(
    row.stimulus => Dict(
        "weights" => Dict(label => row.weights[label] for label in sort(collect(keys(row.weights))))
    ) for row in rows
)

function format_region_key(rows; fn_name = "region_key")
    lines = ["function $(fn_name)() {", "    return ["]

    for row in rows
        weight_text = join(
            ["\"$(label)\" => $(row.weights[label])" for label in sort(collect(keys(row.weights)))],
            ", ",
        )
        push!(lines, "        \"$(row.stimulus)\" => [\"weights\" => [$(weight_text)]],")
    end

    push!(lines, "    ];", "}")
    join(lines, "\n")
end

function save_region_key(rows, path; fn_name = "region_key")
    text = format_region_key(rows; fn_name = fn_name)
    write(path, text * "\n")
    path
end

function extract_topoplot_grid(h)
    tp = h.plots[1]
    xg = tp.xg[]
    yg = tp.yg[]
    Z = tp.data_interpolated[]
    M = tp.mask[]
    Zmask = M .* Z
    return xg, yg, Z, Zmask
end

function add_region_weight_colorbar!(
    f::Union{GridPosition, GridLayout, Figure},
    palette;
    n_bins = 8,
    label = "Region score",
    labelsize = 26,
    ticklabelsize = 22,
    rowgap = 2,
    row_height = 0.16,
    width = 260,
    vertical = false,
)
    gl = if f isa Figure
        f[1, 1] = GridLayout()
    elseif f isa GridLayout
        f
    else
        f[] = GridLayout()
    end
    cmap = cgrad([palette[i] for i in 1:n_bins]; categorical = true)
    cb = Colorbar(
        gl[1, 1];
        colormap = cmap,
        limits = (0.5, n_bins + 0.5),
        ticks = (1:n_bins, string.(1:n_bins)),
        label = label,
        labelsize = labelsize,
        ticklabelsize = ticklabelsize,
        width = width,
        vertical = vertical,
        labelrotation = vertical ? π / 2 : 2π,
    )
    rowgap!(gl, rowgap)
    rowsize!(gl, 1, Auto(row_height))
    return cb
end

function _region_weight_colorbar_config(
    ;
    n_bins = 8,
    label = "Region score",
    labelsize = 26,
    ticklabelsize = 22,
    rowgap = 2,
    row_height = 0.16,
    width = 260,
    vertical = false,
)
    (; n_bins, label, labelsize, ticklabelsize, rowgap, row_height, width, vertical)
end

function _region_weight_scoring_config(
    ;
    score_transform = identity,
    agg = :mean,
    n_bins = 8,
    binning = :quantile,
)
    (; score_transform, agg, n_bins, binning)
end

function _subject_region_topoplot_config(
    ;
    n_bins = 8,
    palette = Dict(i => cgrad(:viridis, n_bins; categorical = true)[i] for i in 1:n_bins),
    show_labels = true,
    template_radius = 150.0f0,
    region_center = (0f0, -0.08f0),
    fontsize = 22,
    fontcolor = :black,
)
    (; palette, show_labels, template_radius, region_center, fontsize, fontcolor)
end

function _subject_region_title_config(;
    title = nothing,
    titlesize = 20,
)
    (; title, titlesize)
end

function plot_subject_region_weights!(
    f::Union{GridPosition, GridLayout, Figure},
    task;
    subject,
    timepoint,
    condition,
    scoring = (;),
    topoplot = (;),
    title_cfg = (;),
    colorbar = nothing,
)
    scoring_cfg = _region_weight_scoring_config(; scoring...)
    topoplot_cfg = _subject_region_topoplot_config(; n_bins = scoring_cfg.n_bins, topoplot...)
    title_cfg = _subject_region_title_config(; title_cfg...)
    gl = if f isa Figure
        f[1, 1] = GridLayout()
    elseif f isa GridLayout
        f
    else
        f[] = GridLayout()
    end

    test = load_erp_subject_avgref(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
    )

    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, _subject_abs_snr(test); labels = test.labels)
    domain = region_head_domain_from_plot(h)

    xg, yg, Z, Zmask = extract_topoplot_grid(h)
    Zscore = scoring_cfg.score_transform.(Zmask)

    rows_t = region_weights_from_grid(
        xg,
        yg,
        Zscore,
        TOPO_REGIONS;
        agg = scoring_cfg.agg,
        mask = h.plots[1].mask[],
        topoplot_domain = domain,
        n_bins = scoring_cfg.n_bins,
        binning = scoring_cfg.binning,
        reverse = true,
    )

    weights = Dict(r.label => r.weight for r in rows_t)

    fig, ax = plot_region_weight_topoplot!(
        gl[1, 1],
        weights;
        show_labels = topoplot_cfg.show_labels,
        template_radius = topoplot_cfg.template_radius,
        region_center = topoplot_cfg.region_center,
        fontsize = topoplot_cfg.fontsize,
        fontcolor = topoplot_cfg.fontcolor,
        palette = topoplot_cfg.palette,
        topoplot_domain = domain,
    )

    ax.title = isnothing(title_cfg.title) ? "SNR: $task | subject $subject | $(timepoint) ms | condition $condition" : title_cfg.title
    ax.titlesize = title_cfg.titlesize

    if !isnothing(colorbar)
        cb_cfg = _region_weight_colorbar_config(; colorbar...)
        cb_cfg = (; cb_cfg..., n_bins = scoring_cfg.n_bins)
        add_region_weight_colorbar!(
            gl[2, 1],
            topoplot_cfg.palette;
            cb_cfg...,
        )
    end

    return fig, ax
end

function plot_subject_region_weights(
    task;
    kwargs...,
)
    f = Figure()
    plot_subject_region_weights!(f, task; kwargs...)
    return f
end

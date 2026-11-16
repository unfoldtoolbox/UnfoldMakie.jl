using CairoMakie
using TopoPlots
using UnfoldMakie

if !@isdefined(Point2f)
    const Point2f = Makie.Point2f
end

@isdefined(task_configs_30_balanced) || include("../../stimuli_data.jl")
@isdefined(_sss_ticks) || include("../debug_sss.jl")
@isdefined(_sss_region_scores_panel_data) || include("../debug_sss_peaks_topo.jl")
@isdefined(plot_region_weight_topoplot!) || include("../../region_detection/plotting.jl")
@isdefined(fit_region_polygons_to_domain) || include("../../region_detection/geometry.jl")

# Pick one balanced example where the max |signal| electrode and max SNR
# electrode differ, then rank such cases by how strongly the SNR winner beats
# the signal winner after division by SE.
function _best_signal_se_snr_shift_case(configs)
    candidates = NamedTuple[]

    for cfg in configs
        for subject in cfg.subjects
            subject_data = load_erp_subject_avgref_or_nothing(
                cfg.task;
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
            )
            isnothing(subject_data) && continue

            signal = avgref_signal(subject_data)
            se = Float64.(subject_data.se)
            snr = abs.(signal ./ se)
            abs_signal = abs.(signal)
            signal_idx = argmax(abs_signal)
            snr_idx = argmax(snr)
            signal_label = String(subject_data.labels[signal_idx])
            snr_label = String(subject_data.labels[snr_idx])
            signal_label == snr_label && continue

            push!(candidates, (
                task = cfg.task,
                subject = subject,
                timepoint = cfg.timepoint,
                condition = cfg.condition,
                subject_data = subject_data,
                signal = signal,
                se = se,
                snr = snr,
                signal_label = signal_label,
                snr_label = snr_label,
                signal_max = abs_signal[signal_idx],
                snr_at_signal = snr[signal_idx],
                snr_max = snr[snr_idx],
                se_at_signal = se[signal_idx],
                se_at_snr = se[snr_idx],
                signal_at_snr = abs_signal[snr_idx],
                ratio = snr[snr_idx] / max(snr[signal_idx], eps()),
            ))
        end
    end

    isempty(candidates) &&
        error("No mismatch case was found for the signal / SE / SNR illustration.")
    sort!(candidates, by = row -> row.ratio, rev = true)
    first(candidates)
end

function _illustration_scalar_topo_panel!(
    slot,
    values,
    labels;
    title,
    colorbar_label,
    colormap,
    colorrange,
    markers = NamedTuple[],
    width = 270,
    height = 240,
    title_size = 19,
    show_colorbar = true,
)
    gl = slot[] = GridLayout()
    ax = Axis(
        gl[1, 1];
        aspect = DataAspect(),
        backgroundcolor = :white,
        title = title,
        titlesize = title_size,
        xlabel = "",
        width = width,
        height = height,
        xautolimitmargin = (0.02, 0.02),
        yautolimitmargin = (0.03, 0.06),
    )
    hidedecorations!(ax, label = false)
    hidespines!(ax)

    h = eeg_topoplot!(
        ax,
        values;
        labels = labels,
        contours = false,
        clip = false,
        colormap = colormap,
        colorrange = colorrange,
        label_text = false,
    )
    limits!(ax, topoplot_head_limits(region_head_domain_from_plot(h))...)

    for marker in markers
        scatter!(
            ax,
            [marker.position[1]],
            [marker.position[2]];
            color = :transparent,
            markersize = 18,
            strokecolor = marker.color,
            strokewidth = 3.5,
        )
    end

    if show_colorbar
        Colorbar(
            gl[2, 1],
            h;
            label = "",
            labelsize = 18,
            ticklabelsize = 13,
            ticks = _sss_ticks(colorrange),
            vertical = false,
            width = width - 18,
            labelrotation = 2π,
        )
    end
    rowsize!(gl, 1, Fixed(height))
    if show_colorbar
        rowsize!(gl, 2, Fixed(58))
        rowgap!(gl, -16)
    end
    gl
end

function illustrate_error_effect(
    ;
    configs = task_configs_30_balanced,
    task = nothing,
    subject = nothing,
    timepoint = nothing,
    condition = nothing,
    filepath = nothing,
)
    chosen = if isnothing(task) && isnothing(subject) && isnothing(timepoint) && isnothing(condition)
        _best_signal_se_snr_shift_case(configs)
    else
        any(isnothing, (task, subject, timepoint, condition)) &&
            error("Pass either all of task / subject / timepoint / condition or none of them.")

        subject_data = load_erp_subject_avgref_or_nothing(
            task;
            subject = subject,
            timepoint = timepoint,
            condition = condition,
        )
        isnothing(subject_data) &&
            error("Missing avgref CSV for $(task)_$(subject) at $(timepoint) ms, condition $(condition).")

        signal = avgref_signal(subject_data)
        se = Float64.(subject_data.se)
        snr = abs.(signal ./ se)
        abs_signal = abs.(signal)
        signal_idx = argmax(abs_signal)
        snr_idx = argmax(snr)

        (
            task = task,
            subject = subject,
            timepoint = timepoint,
            condition = condition,
            subject_data = subject_data,
            signal = signal,
            se = se,
            snr = snr,
            signal_label = String(subject_data.labels[signal_idx]),
            snr_label = String(subject_data.labels[snr_idx]),
            signal_max = abs_signal[signal_idx],
            snr_at_signal = snr[signal_idx],
            snr_max = snr[snr_idx],
            se_at_signal = se[signal_idx],
            se_at_snr = se[snr_idx],
            signal_at_snr = abs_signal[snr_idx],
            ratio = snr[snr_idx] / max(snr[signal_idx], eps()),
        )
    end
    labels = chosen.subject_data.labels

    signal_region_panel = _sss_region_scores_panel_data(
        _sss_region_scores_estimate_field(chosen.subject_data),
        labels;
        regions = TOPO_REGIONS_32,
    )
    snr_region_panel = _sss_region_scores_panel_data(
        _sss_region_scores_snr_field(chosen.subject_data),
        labels;
        regions = TOPO_REGIONS_32,
    )

    case_id = "$(chosen.task)_$(chosen.subject)"
    panel7_cmap = cgrad(:viridis, 10; categorical = true)
    panel7_palette = Dict(i => panel7_cmap[i] for i in 1:10)

    fig = Figure(
        size = (980, 700),
        backgroundcolor = :white,
        figure_padding = (18, 18, 34, 18),
    )
    Label(
        fig[1, 1:3],
        "Effect of Standard error on signal";
        fontsize = 24,
        font = :bold,
    )

    top_gl = fig[2, 1:3] = GridLayout()
    colgap!(top_gl, 14)
    _illustration_scalar_topo_panel!(
        top_gl[1, 1],
        chosen.signal,
        labels;
        title = "Signal",
        colorbar_label = "Voltage [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        colorrange = _sss_signal_limits(chosen.signal),
    )
    _illustration_scalar_topo_panel!(
        top_gl[1, 2],
        chosen.se,
        labels;
        title = "Standard Error",
        colorbar_label = "Std Error",
        colormap = cgrad(:viridis, 10; categorical = true),
        colorrange = _sss_limits(chosen.se),
    )
    _illustration_scalar_topo_panel!(
        top_gl[1, 3],
        chosen.snr,
        labels;
        title = "SNR = |signal| / Std Error",
        colorbar_label = "SNR",
        colormap = cgrad(:batlow, 10; categorical = true),
        colorrange = _sss_snr_limits(chosen.snr),
    )

    region_gl = fig[3, 1:3] = GridLayout()
    colgap!(region_gl, 18)
    for (slot, panel_data, title) in (
        (
            region_gl[1, 1],
            signal_region_panel,
            "Signal region scores\nmax region $(signal_region_panel.argmax)",
        ),
        (
            region_gl[1, 3],
            snr_region_panel,
            "SNR region scores\nmax region $(snr_region_panel.argmax)",
        ),
    )
        ax = Axis(
            slot;
            aspect = DataAspect(),
            backgroundcolor = :white,
            title = title,
            titlesize = 15,
            xlabel = "",
            width = 250,
            height = 228,
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
            palette = panel7_palette,
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
                fontsize = 7,
                color = :black,
            )
        end
    end
    colsize!(region_gl, 1, Fixed(252))
    colsize!(region_gl, 2, Fixed(92))
    colsize!(region_gl, 3, Fixed(252))

    Colorbar(
        region_gl[1, 2];
        colormap = panel7_cmap,
        limits = (0.0, 1.0),
        ticks = (0.0:0.25:1.0, string.(0.0:0.25:1.0)),
        label = "",
        labelsize = 18,
        ticklabelsize = 13,
        height = 208,
        width = 24,
        vertical = true,
    )

    rowsize!(fig.layout, 1, Fixed(34))
    rowgap!(fig.layout, 10)

    resolved_filepath = isnothing(filepath) ?
        joinpath("uncertainty_project", "figures", "signal_se_snr", "$(case_id)_signal_se_snr_shift.png") :
        filepath
    mkpath(dirname(resolved_filepath))
    save(resolved_filepath, fig)

    (
        fig = fig,
        path = resolved_filepath,
        case = (
            task = chosen.task,
            subject = chosen.subject,
            timepoint = chosen.timepoint,
            condition = chosen.condition,
            signal_label = chosen.signal_label,
            snr_label = chosen.snr_label,
            signal_region = signal_region_panel.argmax,
            snr_region = snr_region_panel.argmax,
        ),
    )
end

function illustrate_error_effect_layout(
    ;
    configs = task_configs_30_balanced,
    task = nothing,
    subject = nothing,
    timepoint = nothing,
    condition = nothing,
    filepath = nothing,
)
    chosen = if isnothing(task) && isnothing(subject) && isnothing(timepoint) && isnothing(condition)
        _best_signal_se_snr_shift_case(configs)
    else
        any(isnothing, (task, subject, timepoint, condition)) &&
            error("Pass either all of task / subject / timepoint / condition or none of them.")

        subject_data = load_erp_subject_avgref_or_nothing(
            task;
            subject = subject,
            timepoint = timepoint,
            condition = condition,
        )
        isnothing(subject_data) &&
            error("Missing avgref CSV for $(task)_$(subject) at $(timepoint) ms, condition $(condition).")

        signal = avgref_signal(subject_data)
        se = Float64.(subject_data.se)
        snr = abs.(signal ./ se)
        abs_signal = abs.(signal)
        signal_idx = argmax(abs_signal)
        snr_idx = argmax(snr)

        (
            task = task,
            subject = subject,
            timepoint = timepoint,
            condition = condition,
            subject_data = subject_data,
            signal = signal,
            se = se,
            snr = snr,
            signal_label = String(subject_data.labels[signal_idx]),
            snr_label = String(subject_data.labels[snr_idx]),
            signal_max = abs_signal[signal_idx],
            snr_at_signal = snr[signal_idx],
            snr_max = snr[snr_idx],
            se_at_signal = se[signal_idx],
            se_at_snr = se[snr_idx],
            signal_at_snr = abs_signal[snr_idx],
            ratio = snr[snr_idx] / max(snr[signal_idx], eps()),
        )
    end

    labels = chosen.subject_data.labels
    case_id = "$(chosen.task)_$(chosen.subject)"
    se_valid = [value for value in chosen.se if isfinite(value)]
    isempty(se_valid) && error("No finite SE values were available for the signal-only SNR illustration.")
    signal_only_snr = abs.(chosen.signal ./ mean(se_valid))

    fig = Figure(
        size = (980, 720),
        backgroundcolor = :white,
        figure_padding = (18, 18, 34, 18),
    )
    Label(
        fig[1, 1:3],
        "Effect of Standard Error on Signal";
        fontsize = 24,
        font = :bold,
    )

    alt_top_gl = fig[2, 1:3] = GridLayout()
    colgap!(alt_top_gl, 18)
    _illustration_scalar_topo_panel!(
        alt_top_gl[1, 1],
        chosen.signal,
        labels;
        title = "Signal",
        colorbar_label = "Voltage [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        colorrange = _sss_signal_limits(chosen.signal),
        width = 230,
        height = 180,
    )
    Label(
        alt_top_gl[1, 2],
        "→";
        fontsize = 54,
        font = :bold,
        halign = :center,
        valign = :center,
    )
    _illustration_scalar_topo_panel!(
        alt_top_gl[1, 3],
        signal_only_snr,
        labels;
        title = "Signal-only SNR",
        colorbar_label = "SNR",
        colormap = cgrad(:batlow, 10; categorical = true),
        colorrange = _sss_snr_limits(signal_only_snr),
        width = 230,
        height = 180,
    )
    colsize!(alt_top_gl, 1, Fixed(230))
    colsize!(alt_top_gl, 2, Fixed(54))
    colsize!(alt_top_gl, 3, Fixed(230))

    alt_bottom_gl = fig[3, 1:3] = GridLayout()
    colgap!(alt_bottom_gl, 18)
    _illustration_scalar_topo_panel!(
        alt_bottom_gl[1, 1],
        chosen.signal,
        labels;
        title = "Signal",
        colorbar_label = "Voltage [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        colorrange = _sss_signal_limits(chosen.signal),
        width = 210,
        height = 165,
    )
    Label(
        alt_bottom_gl[1, 2],
        "/";
        fontsize = 58,
        font = :bold,
        halign = :center,
        valign = :center,
    )
    _illustration_scalar_topo_panel!(
        alt_bottom_gl[1, 3],
        chosen.se,
        labels;
        title = "Std Error",
        colorbar_label = "Std Error",
        colormap = cgrad(:viridis, 10; categorical = true),
        colorrange = _sss_limits(chosen.se),
        width = 210,
        height = 165,
    )
    Label(
        alt_bottom_gl[1, 4],
        "→";
        fontsize = 54,
        font = :bold,
        halign = :center,
        valign = :center,
    )
    _illustration_scalar_topo_panel!(
        alt_bottom_gl[1, 5],
        chosen.snr,
        labels;
        title = "Signal + Std Error SNR",
        colorbar_label = "SNR",
        colormap = cgrad(:batlow, 10; categorical = true),
        colorrange = _sss_snr_limits(chosen.snr),
        width = 210,
        height = 165,
    )
    colsize!(alt_bottom_gl, 1, Fixed(210))
    colsize!(alt_bottom_gl, 2, Fixed(54))
    colsize!(alt_bottom_gl, 3, Fixed(210))
    colsize!(alt_bottom_gl, 4, Fixed(54))
    colsize!(alt_bottom_gl, 5, Fixed(210))

    rowsize!(fig.layout, 1, Fixed(34))
    rowgap!(fig.layout, 14)

    resolved_filepath = isnothing(filepath) ?
        joinpath("uncertainty_project", "figures", "signal_se_snr", "$(case_id)_signal_se_snr_layout.png") :
        filepath
    mkpath(dirname(resolved_filepath))
    save(resolved_filepath, fig)

    (
        fig = fig,
        path = resolved_filepath,
        case = (
            task = chosen.task,
            subject = chosen.subject,
            timepoint = chosen.timepoint,
            condition = chosen.condition,
            signal_label = chosen.signal_label,
            snr_label = chosen.snr_label,
        ),
    )
end

function illustrate_error_effect_region_layout(
    ;
    configs = task_configs_30_balanced,
    task = nothing,
    subject = nothing,
    timepoint = nothing,
    condition = nothing,
    filepath = nothing,
)
    chosen = if isnothing(task) && isnothing(subject) && isnothing(timepoint) && isnothing(condition)
        _best_signal_se_snr_shift_case(configs)
    else
        any(isnothing, (task, subject, timepoint, condition)) &&
            error("Pass either all of task / subject / timepoint / condition or none of them.")

        subject_data = load_erp_subject_avgref_or_nothing(
            task;
            subject = subject,
            timepoint = timepoint,
            condition = condition,
        )
        isnothing(subject_data) &&
            error("Missing avgref CSV for $(task)_$(subject) at $(timepoint) ms, condition $(condition).")

        signal = avgref_signal(subject_data)
        se = Float64.(subject_data.se)
        snr = abs.(signal ./ se)
        abs_signal = abs.(signal)
        signal_idx = argmax(abs_signal)
        snr_idx = argmax(snr)

        (
            task = task,
            subject = subject,
            timepoint = timepoint,
            condition = condition,
            subject_data = subject_data,
            signal = signal,
            se = se,
            snr = snr,
            signal_label = String(subject_data.labels[signal_idx]),
            snr_label = String(subject_data.labels[snr_idx]),
            signal_max = abs_signal[signal_idx],
            snr_at_signal = snr[signal_idx],
            snr_max = snr[snr_idx],
            se_at_signal = se[signal_idx],
            se_at_snr = se[snr_idx],
            signal_at_snr = abs_signal[snr_idx],
            ratio = snr[snr_idx] / max(snr[signal_idx], eps()),
        )
    end

    labels = chosen.subject_data.labels
    case_id = "$(chosen.task)_$(chosen.subject)"
    se_valid = [value for value in chosen.se if isfinite(value)]
    isempty(se_valid) && error("No finite SE values were available for the signal-only SNR illustration.")
    signal_only_snr = abs.(chosen.signal ./ mean(se_valid))
    signal_only_snr_region_panel = _sss_region_scores_panel_data(
        signal_only_snr,
        labels;
        regions = TOPO_REGIONS_32,
    )
    combined_snr_region_panel = _sss_region_scores_panel_data(
        _sss_region_scores_snr_field(chosen.subject_data),
        labels;
        regions = TOPO_REGIONS_32,
    )
    panel7_cmap = cgrad(:batlow, 10; categorical = true)
    panel7_palette = Dict(i => panel7_cmap[i] for i in 1:10)
    signal_only_snr_label = signal_only_snr_region_panel.argmax
    combined_snr_label = combined_snr_region_panel.argmax

    fig = Figure(
        size = (880, 530),
        backgroundcolor = :white,
        figure_padding = (4, 4, 6, 10),
    )
    Label(
        fig[1, 1:3],
        "Effect of Standard error on signal";
        fontsize = 24,
        font = :bold,
    )

    body_gl = fig[2, 1:3] = GridLayout()
    colgap!(body_gl, 10)
    rowgap!(body_gl, 0)
    left_gl = body_gl[1:2, 1] = GridLayout()
    rowgap!(left_gl, 0)
    right_gl = body_gl[1:2, 5] = GridLayout()
    rowgap!(right_gl, 0)
    _illustration_scalar_topo_panel!(
        left_gl[1, 1],
        chosen.signal,
        labels;
        title = "Signal",
        colorbar_label = "Voltage [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        colorrange = _sss_signal_limits(chosen.signal),
        width = 230,
        height = 180,
        show_colorbar = false,
    )
    top_region_gl = right_gl[1, 1] = GridLayout()
    top_region_ax = Axis(
        top_region_gl[1, 1];
        aspect = DataAspect(),
        backgroundcolor = :white,
        title = "Signal to noise ratio",
        titlesize = 19,
        xlabel = "",
        width = 230,
        height = 180,
        xautolimitmargin = (0.02, 0.02),
        yautolimitmargin = (0.03, 0.06),
    )
    hidedecorations!(top_region_ax, label = false)
    hidespines!(top_region_ax)
    plot_region_weight_topoplot!(
        top_region_ax,
        signal_only_snr_region_panel.weights;
        regions = signal_only_snr_region_panel.regions,
        show_labels = false,
        missing_color = :white,
        strokecolor = :black,
        strokewidth = 0.95,
        palette = panel7_palette,
        topoplot_domain = signal_only_snr_region_panel.topoplot_domain,
        template_center = signal_only_snr_region_panel.template_center,
        template_radius = signal_only_snr_region_panel.template_radius,
        region_center = signal_only_snr_region_panel.head_center,
        head_radius = signal_only_snr_region_panel.head_radius,
    )
    top_region_fitted = fit_region_polygons_to_domain(
        signal_only_snr_region_panel.regions,
        signal_only_snr_region_panel.topoplot_domain;
        template_center = signal_only_snr_region_panel.template_center,
        template_radius = signal_only_snr_region_panel.template_radius,
        head_center = signal_only_snr_region_panel.head_center,
        head_radius = signal_only_snr_region_panel.head_radius,
    )
    for (reg, poly) in zip(signal_only_snr_region_panel.regions, top_region_fitted.polygons)
        center = polygon_centroid(poly)
        text!(
            top_region_ax,
            center;
            text = get(signal_only_snr_region_panel.region_text, string(reg.label), ""),
            align = (:center, :center),
            fontsize = 7,
            color = :black,
        )
    end
    rowsize!(top_region_gl, 1, Fixed(180))
    Label(
        body_gl[1, 2:4],
        "→";
        fontsize = 54,
        font = :bold,
        halign = :center,
        valign = :center,
    )
    _illustration_scalar_topo_panel!(
        left_gl[2, 1],
        chosen.signal,
        labels;
        title = "",
        colorbar_label = "Voltage [µV]",
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        colorrange = _sss_signal_limits(chosen.signal),
        width = 230,
        height = 180,
    )
    _illustration_scalar_topo_panel!(
        body_gl[2, 3],
        chosen.se,
        labels;
        title = "",
        colorbar_label = "Std Error",
        colormap = cgrad(:viridis, 10; categorical = true),
        colorrange = _sss_limits(chosen.se),
        width = 230,
        height = 180,
    )
    overlay_22 = Label(
        body_gl[2, 3, Top()],
        "Std Error";
        fontsize = 19,
        font = :bold,
        padding = (0, 0, 12, 0),
        halign = :center,
        valign = :bottom,
        tellwidth = false,
        tellheight = false,
    )
    translate!(overlay_22.blockscene, 0, 0, 10_000)
    bottom_region_gl = right_gl[2, 1] = GridLayout()
    bottom_region_ax = Axis(
        bottom_region_gl[1, 1];
        aspect = DataAspect(),
        backgroundcolor = :white,
        title = "",
        titlesize = 17,
        xlabel = "",
        width = 230,
        height = 180,
        xautolimitmargin = (0.02, 0.02),
        yautolimitmargin = (0.03, 0.06),
    )
    hidedecorations!(bottom_region_ax, label = false)
    hidespines!(bottom_region_ax)
    plot_region_weight_topoplot!(
        bottom_region_ax,
        combined_snr_region_panel.weights;
        regions = combined_snr_region_panel.regions,
        show_labels = false,
        missing_color = :white,
        strokecolor = :black,
        strokewidth = 0.95,
        palette = panel7_palette,
        topoplot_domain = combined_snr_region_panel.topoplot_domain,
        template_center = combined_snr_region_panel.template_center,
        template_radius = combined_snr_region_panel.template_radius,
        region_center = combined_snr_region_panel.head_center,
        head_radius = combined_snr_region_panel.head_radius,
    )
    bottom_region_fitted = fit_region_polygons_to_domain(
        combined_snr_region_panel.regions,
        combined_snr_region_panel.topoplot_domain;
        template_center = combined_snr_region_panel.template_center,
        template_radius = combined_snr_region_panel.template_radius,
        head_center = combined_snr_region_panel.head_center,
        head_radius = combined_snr_region_panel.head_radius,
    )
    for (reg, poly) in zip(combined_snr_region_panel.regions, bottom_region_fitted.polygons)
        center = polygon_centroid(poly)
        text!(
            bottom_region_ax,
            center;
            text = get(combined_snr_region_panel.region_text, string(reg.label), ""),
            align = (:center, :center),
            fontsize = 7,
            color = :black,
        )
    end
    Colorbar(
        bottom_region_gl[2, 1];
        colormap = panel7_cmap,
        limits = (0.0, 1.0),
        ticks = (0.0:0.25:1.0, string.(0.0:0.25:1.0)),
        label = "",
        labelsize = 18,
        ticklabelsize = 13,
        width = 212,
        vertical = false,
        labelrotation = 2π,
    )
    rowsize!(bottom_region_gl, 1, Fixed(180))
    rowsize!(bottom_region_gl, 2, Fixed(58))
    rowgap!(bottom_region_gl, -16)
    Label(
        body_gl[2, 2],
        "/";
        fontsize = 58,
        font = :bold,
        halign = :center,
        valign = :center,
    )
    Label(
        body_gl[2, 4],
        "→";
        fontsize = 54,
        font = :bold,
        halign = :center,
        valign = :center,
    )
    colsize!(body_gl, 1, Fixed(230))
    colsize!(body_gl, 2, Fixed(54))
    colsize!(body_gl, 3, Fixed(230))
    colsize!(body_gl, 4, Fixed(54))
    colsize!(body_gl, 5, Fixed(230))
    rowsize!(left_gl, 1, Fixed(180))
    rowsize!(left_gl, 2, Fixed(222))
    rowsize!(right_gl, 1, Fixed(180))
    rowsize!(right_gl, 2, Fixed(222))
    rowsize!(body_gl, 1, Fixed(180))
    rowsize!(body_gl, 2, Fixed(222))

    rowsize!(fig.layout, 1, Fixed(28))
    rowgap!(fig.layout, 4)

    resolved_filepath = isnothing(filepath) ?
        joinpath("uncertainty_project", "figures", "signal_se_snr", "$(case_id)_signal_se_snr_region_layout.png") :
        filepath
    mkpath(dirname(resolved_filepath))
    save(resolved_filepath, fig)

    (
        fig = fig,
        path = resolved_filepath,
        case = (
            task = chosen.task,
            subject = chosen.subject,
            timepoint = chosen.timepoint,
            condition = chosen.condition,
            signal_label = chosen.signal_label,
            snr_label = chosen.snr_label,
            signal_only_snr_label = signal_only_snr_label,
            combined_snr_label = combined_snr_label,
        ),
    )
end

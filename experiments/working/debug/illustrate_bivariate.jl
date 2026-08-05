@isdefined(_distinct_tick_labels) || include("../plot_fitting/individual_uncert.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")

function plot_bivariate_pipeline!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    title = "Bivariate pipeline",
    uncert_label = "Uncertainty",
    colorrange_mode = :diverging_balanced,
    colorbox = _colorbox_corner_teuling3,
    BG = RGBf(0.98, 0.98, 0.98),
    figure_title_size = 26,
    panel_title_size = 24,
    note_size = 11,
    final_topo_size = 320,
    input_topo_width = final_topo_size,
    input_topo_height = final_topo_size,
    input_colorbar_width = final_topo_size,
    mapping_panel_size = 240,
    col_gap = 10,
    row_gap = 14,
)
    root = f isa Figure ? f.layout :
           f isa GridLayout ? f :
           (f[] = GridLayout())

    current_row = 1
    if !isnothing(title) && !isempty(String(title))
        Label(
            root[current_row, 1:5],
            title;
            fontsize = figure_title_size,
            font = :bold,
            halign = :center,
            tellwidth = false,
            padding = (0, 0, 4, 0),
        )
        current_row += 1
    end

    body = root[current_row, 1:5] = GridLayout()
    colgap!(body, col_gap)
    rowgap!(body, row_gap)
    right_cluster_gap = min(col_gap, 4)
    panel34_gap = right_cluster_gap
    right_cluster_extra_width = 12
    final_panel_extra_width = 28
    right_topo_title_band_height = 3 * panel_title_size + 20
    signal_colors5 = collect(cgrad(collect(colorbox[1, :]), 5; categorical = true).colors)
    uncert_colors5 = collect(cgrad(collect(colorbox[:, 1]), 5; categorical = true).colors)
    signal_cmap5 = cgrad(signal_colors5, 5; categorical = true)
    uncert_cmap5 = cgrad(uncert_colors5, 5; categorical = true)

    let
        topo_args =
            positions !== nothing ? (; positions = positions) :
            labels !== nothing    ? (; labels = labels) :
                                    error("Either positions or labels must be provided.")
        values = vec_estimate
        color_limits = _shared_scalar_topoplot_range(values; colorrange_mode = colorrange_mode)
        estimate_tick_positions = Float32.(collect(LinRange(color_limits[1], color_limits[2], 5)))
        estimate_tick_labels = _distinct_tick_labels(estimate_tick_positions; min_digits = 1, max_digits = 4)
        estimate_bin_edges = Float32.(collect(LinRange(color_limits[1], color_limits[2], 6)))
        display_values = map(values) do v
            if !ismissing(v) && isfinite(v)
                Float32(clamp(searchsortedlast(estimate_bin_edges, Float32(v)) - 1, 1, 5))
            else
                NaN32
            end
        end
        panel = body[1, 1] = GridLayout()
        colgap!(panel, 0)
        rowgap!(panel, 4)
        Label(
            panel[1, 1:2],
            "1. Signal";
            fontsize = panel_title_size,
            font = :bold,
            halign = :center,
            tellwidth = false,
        )
        topo_ax = Axis(
            panel[2, 2];
            backgroundcolor = BG,
            width = input_topo_width,
            height = input_topo_height,
            aspect = DataAspect(),
            limits = (-1.25, 1.25, -1.25, 1.2),
        )
        h = eeg_topoplot!(
            topo_ax,
            display_values;
            topo_args...,
            _scalar_topoplot_visual(;
                colormap = signal_colors5,
                contours = false,
                colorrange = (1, 5),
            )...,
            interpolation = TopoPlots.NullInterpolator(),
            label_text = false,
            label_scatter = (;
                markersize = 35,
                strokecolor = :black,
                strokewidth = 0.6,
            ),
        )
        hidespines!(topo_ax)
        hidedecorations!(topo_ax)
        Colorbar(
            panel[2, 1];
            colormap = signal_cmap5,
            limits = color_limits,
            label = "Voltage [µV]",
            labelsize = 22,
            ticklabelsize = 18,
            ticksize = 8,
            tickwidth = 2,
            ticks = (estimate_tick_positions, estimate_tick_labels),
            vertical = true,
            flipaxis = false,
            flip_vertical_label = false,
            halign = :right,
            width = 12,
            height = input_colorbar_width,
        )
        colsize!(panel, 1, Fixed(54))
        colsize!(panel, 2, Fixed(input_topo_width))
        rowsize!(panel, 2, Auto())
    end

    let
        topo_args =
            positions !== nothing ? (; positions = positions) :
            labels !== nothing    ? (; labels = labels) :
                                    error("Either positions or labels must be provided.")
        values = vec_uncert
        finite_values = [Float64(v) for v in vec(values) if !ismissing(v) && isfinite(v)]
        color_limits = Float32.((minimum(finite_values), maximum(finite_values)))
        uncertainty_tick_positions = Float32.(collect(LinRange(color_limits[1], color_limits[2], 5)))
        uncertainty_tick_labels = _distinct_tick_labels(uncertainty_tick_positions; min_digits = 2, max_digits = 4)
        uncertainty_bin_edges = Float32.(collect(LinRange(color_limits[1], color_limits[2], 6)))
        display_values = map(values) do v
            if !ismissing(v) && isfinite(v)
                Float32(clamp(searchsortedlast(uncertainty_bin_edges, Float32(v)) - 1, 1, 5))
            else
                NaN32
            end
        end
        panel = body[2, 1] = GridLayout()
        colgap!(panel, 0)
        rowgap!(panel, 4)
        Label(
            panel[1, 1:2],
            "2. Uncertainty";
            fontsize = panel_title_size,
            font = :bold,
            halign = :center,
            tellwidth = false,
        )
        topo_ax = Axis(
            panel[2, 2];
            backgroundcolor = BG,
            width = input_topo_width,
            height = input_topo_height,
            aspect = DataAspect(),
            limits = (-1.25, 1.25, -1.25, 1.2),
        )
        h = eeg_topoplot!(
            topo_ax,
            display_values;
            topo_args...,
            _scalar_topoplot_visual(;
                colormap = uncert_colors5,
                contours = false,
                colorrange = (1, 5),
            )...,
            interpolation = TopoPlots.NullInterpolator(),
            label_text = false,
            label_scatter = (;
                markersize = 35,
                strokecolor = :black,
                strokewidth = 0.6,
            ),
        )
        hidespines!(topo_ax)
        hidedecorations!(topo_ax)
        Colorbar(
            panel[2, 1];
            colormap = uncert_cmap5,
            limits = color_limits,
            label = uncert_label,
            labelsize = 22,
            ticklabelsize = 18,
            ticksize = 8,
            tickwidth = 2,
            ticks = (uncertainty_tick_positions, uncertainty_tick_labels),
            vertical = true,
            flipaxis = false,
            flip_vertical_label = false,
            halign = :right,
            width = 12,
            height = input_colorbar_width,
        )
        colsize!(panel, 1, Fixed(54))
        colsize!(panel, 2, Fixed(input_topo_width))
        rowsize!(panel, 2, Auto())
    end

    let
        n_rows, n_cols = size(colorbox)
        U01, V01, _, _ = normalize_bivariate(
            Float32.(vec_estimate),
            Float32.(vec_uncert),
            Float32.(vec_estimate),
            Float32.(vec_uncert);
            method = :robust_minmax,
            qrange = (0.005, 0.995),
            flip_v = false,
        )
        finite_idx = [idx for idx in eachindex(U01, V01) if isfinite(U01[idx]) && isfinite(V01[idx])]
        xs = [1 + Float64(U01[idx]) * (n_cols - 1) for idx in finite_idx]
        ys = [1 + Float64(V01[idx]) * (n_rows - 1) for idx in finite_idx]
        colors = [sample_bivariate(colorbox, U01[idx], V01[idx]; mode = :nearest) for idx in finite_idx]
        wrapper = body[1:2, 2] = GridLayout()
        rowgap!(wrapper, 2)
        rowsize!(wrapper, 1, Fixed(right_topo_title_band_height))
        Label(
            wrapper[1, 1],
            "3. Electrode\npairs in\ncolorbox";
            fontsize = panel_title_size,
            font = :bold,
            halign = :center,
            valign = :bottom,
            tellwidth = false,
        )
        plot_wrapper = wrapper[2, 1] = GridLayout()
        rowgap!(plot_wrapper, 0)
        plot_wrapper[1, 1] = GridLayout()
        gl = plot_wrapper[2, 1] = GridLayout()
        plot_wrapper[3, 1] = GridLayout()
        rowsize!(plot_wrapper, 1, Relative(0.5))
        rowsize!(plot_wrapper, 2, Auto())
        rowsize!(plot_wrapper, 3, Relative(0.5))
        xticks = collect(range(
            UnfoldMakie._topo_range_from_values(
                vec_estimate;
                colorrange_mode = colorrange_mode,
            )...;
            length = n_cols,
        ))
        yticks = collect(range(extrema(vec_uncert)...; length = n_rows))
        label_inds_x = [1, 3, n_cols]
        label_inds_y = [1, 3, n_rows]
        xticks_label = [i in label_inds_x ? _tick_label_1dp(x) : "" for (i, x) in enumerate(xticks)]
        yticks_label = [i in label_inds_y ? _tick_label_1dp(y) : "" for (i, y) in enumerate(yticks)]
        ax = Axis(
            gl[1, 1];
            aspect = DataAspect(),
            backgroundcolor = BG,
            xlabel = "Voltage [µV]",
            ylabel = uncert_label,
            xlabelsize = 22,
            ylabelsize = 22,
            xticklabelsize = 18,
            yticklabelsize = 18,
            ylabelpadding = 0,
            xticks = (collect(1:n_cols), xticks_label),
            yticks = (collect(1:n_rows), yticks_label),
            width = mapping_panel_size,
            height = mapping_panel_size,
        )
        heatmap!(ax, colorbox'; colormap = vec(colorbox))
        for x in 0.5:1:(n_cols + 0.5)
            lines!(ax, [x, x], [0.5, n_rows + 0.5]; color = (:black, 0.35), linewidth = 0.8)
        end
        for y in 0.5:1:(n_rows + 0.5)
            lines!(ax, [0.5, n_cols + 0.5], [y, y]; color = (:black, 0.35), linewidth = 0.8)
        end
        scatter!(
            ax,
            xs,
            ys;
            color = [RGBAf(red(c), green(c), blue(c), 1.0) for c in colors],
            markersize = 10,
            strokecolor = :black,
            strokewidth = 1.0,
        )
    end

    let
        topo_args =
            positions !== nothing ? (; positions = positions) :
            labels !== nothing    ? (; labels = labels) :
                                    error("Either positions or labels must be provided.")
        wrapper = body[1:2, 3] = GridLayout()
        rowgap!(wrapper, 2)
        rowsize!(wrapper, 1, Fixed(right_topo_title_band_height))
        Label(
            wrapper[1, 1],
            "4. Bivariate\ntopoplot without\ninterpolation";
            fontsize = panel_title_size,
            font = :bold,
            halign = :center,
            valign = :bottom,
            tellwidth = false,
        )
        plot_wrapper = wrapper[2, 1] = GridLayout()
        rowgap!(plot_wrapper, 0)
        plot_wrapper[1, 1] = GridLayout()
        gl = plot_wrapper[2, 1] = GridLayout()
        plot_wrapper[3, 1] = GridLayout()
        rowsize!(plot_wrapper, 1, Relative(0.5))
        rowsize!(plot_wrapper, 2, Auto())
        rowsize!(plot_wrapper, 3, Relative(0.5))
        topo_ax = Axis(
            gl[1, 1];
            backgroundcolor = BG,
            width = input_topo_width,
            height = input_topo_height,
            aspect = DataAspect(),
            limits = (-1.25, 1.25, -1.25, 1.2),
        )
        set_topoplot_bivariate!(;
            colorbox = colorbox,
            norm_method = :robust_minmax,
            norm_qrange = (0.005, 0.995),
            norm_flip_v = false,
            sample_mode = :nearest,
        )
        TopoPlots.eeg_topoplot!(
            topo_ax,
            (vec_estimate, vec_uncert);
            topo_args...,
            contours = false,
            interpolation = TopoPlots.NullInterpolator(),
            label_text = false,
            label_scatter = (;
                markersize = 35,
                strokecolor = :black,
                strokewidth = 0.6,
            ),
        )
        hidespines!(topo_ax)
        hidedecorations!(topo_ax)
    end

    let
        topo_args =
            positions !== nothing ? (; positions = positions) :
            labels !== nothing    ? (; labels = labels) :
                                    error("Either positions or labels must be provided.")
        tmpfig = Figure(size = (10, 10))
        h_est = eeg_topoplot!(
            Axis(tmpfig[1, 1]),
            vec_estimate;
            topo_args...,
            contours = false,
            clip = false,
            label_text = false,
            label_scatter = false,
        )
        h_unc = eeg_topoplot!(
            Axis(tmpfig[1, 2]),
            vec_uncert;
            topo_args...,
            contours = false,
            clip = false,
            label_text = false,
            label_scatter = false,
        )
        tp_est = h_est.plots[1]
        tp_unc = h_unc.plots[1]
        xg = Float32.(tp_est.xg[])
        yg = Float32.(tp_est.yg[])
        U = Float32.(tp_est.data_interpolated[])
        V = Float32.(tp_unc.data_interpolated[])
        mask = BitMatrix(tp_est.mask[] .& tp_unc.mask[])
        U01, V01, _, _ = normalize_bivariate(
            U,
            V,
            Float32.(vec_estimate),
            Float32.(vec_uncert);
            method = :robust_minmax,
            qrange = (0.005, 0.995),
            flip_v = false,
        )
        xs = Float64[]
        ys = Float64[]
        colors = RGBAf[]
        @inbounds for i in axes(U01, 1), j in axes(U01, 2)
            mask[i, j] || continue
            u = U01[i, j]
            v = V01[i, j]
            (isfinite(u) && isfinite(v)) || continue
            push!(xs, Float64(xg[i]))
            push!(ys, Float64(yg[j]))
            push!(colors, sample_bivariate(colorbox, u, v; mode = :nearest))
        end
        grid_point_count = replace(string(length(xs)), r"(?<=\d)(?=(\d{3})+$)" => ".")

        wrapper = body[1:2, 4] = GridLayout()
        rowgap!(wrapper, 2)
        rowsize!(wrapper, 1, Fixed(right_topo_title_band_height))
        Label(
            wrapper[1, 1],
            "5. Interpolated\nhead-grid points\n(n = $(grid_point_count))";
            fontsize = panel_title_size,
            font = :bold,
            halign = :center,
            valign = :bottom,
            tellwidth = false,
        )
        plot_wrapper = wrapper[2, 1] = GridLayout()
        rowgap!(plot_wrapper, 0)
        plot_wrapper[1, 1] = GridLayout()
        gl = plot_wrapper[2, 1] = GridLayout()
        plot_wrapper[3, 1] = GridLayout()
        rowsize!(plot_wrapper, 1, Relative(0.5))
        rowsize!(plot_wrapper, 2, Auto())
        rowsize!(plot_wrapper, 3, Relative(0.5))
        topo_ax = Axis(
            gl[1, 1];
            backgroundcolor = BG,
            width = input_topo_width,
            height = input_topo_height,
            aspect = DataAspect(),
            limits = (-1.25, 1.25, -1.25, 1.2),
        )
        TopoPlots.eeg_topoplot!(
            topo_ax,
            zeros(Float32, length(vec_estimate));
            topo_args...,
            contours = false,
            interpolation = TopoPlots.NullInterpolator(),
            label_text = false,
            label_scatter = false,
        )
        scatter!(
            topo_ax,
            xs,
            ys;
            color = colors,
            markersize = 4.5,
            strokecolor = :black,
            strokewidth = 0.15,
        )
        hidespines!(topo_ax)
        hidedecorations!(topo_ax)
    end

    final_wrapper = body[1:2, 5] = GridLayout()
    rowgap!(final_wrapper, 2)
    rowsize!(final_wrapper, 1, Fixed(right_topo_title_band_height))
    Label(
        final_wrapper[1, 1],
        "6. Final\nbivariate\ntopoplot";
        fontsize = panel_title_size,
        font = :bold,
        halign = :center,
        valign = :bottom,
        tellwidth = false,
    )
    final_plot_wrapper = final_wrapper[2, 1] = GridLayout()
    rowgap!(final_plot_wrapper, 0)
    final_plot_wrapper[1, 1] = GridLayout()
    final_gl = final_plot_wrapper[2, 1] = GridLayout()
    final_plot_wrapper[3, 1] = GridLayout()
    rowsize!(final_plot_wrapper, 1, Relative(0.5))
    rowsize!(final_plot_wrapper, 2, Auto())
    rowsize!(final_plot_wrapper, 3, Relative(0.5))
    plot_bivariate_corner!(
        final_gl[1, 1],
        vec_estimate,
        vec_uncert;
        positions = positions,
        labels = labels,
        uncert_label = uncert_label,
        colorrange_mode = colorrange_mode,
        show_colorbox = false,
        colorbox = colorbox,
        topo_size = final_topo_size,
        BG = BG,
    )
    colsize!(body, 1, Fixed(input_topo_width + 54))
    colsize!(body, 2, Fixed(mapping_panel_size + 40))
    colsize!(body, 3, Fixed(input_topo_width + right_cluster_extra_width))
    colsize!(body, 4, Fixed(input_topo_width + right_cluster_extra_width))
    colsize!(body, 5, Fixed(final_topo_size + final_panel_extra_width))
    colgap!(body, 2, panel34_gap)
    colgap!(body, 3, right_cluster_gap)
    colgap!(body, 4, right_cluster_gap)
    rowsize!(body, 1, Auto())
    rowsize!(body, 2, Auto())
    root
end

function plot_bivariate_pipeline(
    vec_estimate,
    vec_uncert;
    figure_size = nothing,
    figure_padding = (20, 20, 12, 12),
    BG = RGBf(0.98, 0.98, 0.98),
    kwargs...,
)
    resolved_final_topo_size = get(kwargs, :final_topo_size, 320)
    resolved_input_topo_width = get(kwargs, :input_topo_width, resolved_final_topo_size)
    resolved_input_topo_height = get(kwargs, :input_topo_height, resolved_final_topo_size)
    resolved_input_colorbar_width = get(kwargs, :input_colorbar_width, resolved_final_topo_size)
    resolved_mapping_panel_size = get(kwargs, :mapping_panel_size, 240)
    resolved_col_gap = get(kwargs, :col_gap, 10)
    resolved_row_gap = get(kwargs, :row_gap, 14)
    resolved_right_cluster_gap = min(resolved_col_gap, 4)
    resolved_panel34_gap = resolved_right_cluster_gap
    right_cluster_extra_width = 12
    final_panel_extra_width = 28
    resolved_panel_title_size = get(kwargs, :panel_title_size, 24)
    resolved_figure_title_size = get(kwargs, :figure_title_size, 26)
    resolved_title = get(kwargs, :title, "Bivariate pipeline")
    input_panel_block_height =
        max(resolved_input_topo_height, resolved_input_colorbar_width) + resolved_panel_title_size + 40
    mapping_panel_block_height =
        resolved_mapping_panel_size + resolved_panel_title_size + 52
    final_panel_block_height =
        resolved_final_topo_size + resolved_panel_title_size + 30
    content_height = max(
        2 * input_panel_block_height + resolved_row_gap,
        mapping_panel_block_height,
        final_panel_block_height,
    )
    content_width =
        (resolved_input_topo_width + 54) +
        (resolved_mapping_panel_size + 40) +
        (resolved_input_topo_width + right_cluster_extra_width) +
        (resolved_input_topo_width + right_cluster_extra_width) +
        (resolved_final_topo_size + final_panel_extra_width) +
        resolved_col_gap +
        resolved_panel34_gap +
        2 * resolved_right_cluster_gap +
        80
    vertical_padding = figure_padding[3] + figure_padding[4]
    horizontal_padding = figure_padding[1] + figure_padding[2]
    title_block_height =
        (isnothing(resolved_title) || isempty(String(resolved_title))) ? 0 :
        resolved_figure_title_size + 18
    resolved_figure_size = something(
        figure_size,
        (
            max(1680, ceil(Int, content_width + horizontal_padding)),
            ceil(Int, content_height + title_block_height + vertical_padding),
        ),
    )
    f = Figure(
        size = resolved_figure_size,
        backgroundcolor = BG,
        figure_padding = figure_padding,
    )
    plot_bivariate_pipeline!(f, vec_estimate, vec_uncert; BG = BG, kwargs...)
    return f
end

function bivariate_pipeline_case_figure(
    task;
    subject,
    timepoint,
    condition,
    title = nothing,
    figure_size = nothing,
    figure_padding = (20, 20, 12, 12),
)
    subject_data = load_erp_subject_avgref_or_nothing(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
    )
    isnothing(subject_data) && return nothing

    plot_bivariate_pipeline(
        avgref_signal(subject_data),
        Float64.(subject_data.se);
        labels = subject_data.labels,
        title = something(title, "Bivariate pipeline"),
        uncert_label = "Std Error",
        figure_size = figure_size,
        figure_padding = figure_padding,
    )
end

# Examples:
#=  =#

#= begin
    fig = bivariate_pipeline_case_figure(
        "P3";
        subject = 4,
        timepoint = 129,
        condition = 1,
        title = "P3_4 bivariate construction",
    )
    fig
end =#

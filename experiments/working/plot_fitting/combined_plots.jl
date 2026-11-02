include("../stimuli_data.jl")
@isdefined(load_erp_subject_avgref) || include("../region_detection/rereferencing.jl")
include("individual_uncert.jl")

function _combined_uncerts_layout_style(layout_mode)
    if layout_mode == :page_landscape
        return (
            adjacent_colorbar_labelsize = 18,
            adjacent_colorbar_ticklabelsize = 12,
            adjacent_colorbar_width = 128,
            adjacent_axis_labelsize = 18,
            bivariate_topo_size = 220,
            bivariate_colorbox_size = 96,
            bivariate_axis_labelsize = 14,
            bivariate_axis_ticklabelsize = 10,
            bivariate_colorbox_gap = 8,
            markers_axis_labelsize = 18,
            markers_colorbar_labelsize = 18,
            markers_colorbar_ticklabelsize = 12,
            markers_colorbar_height = 170,
            markers_topo_size = 170,
            markers_legend_labelsize = 13,
            markers_legend_titlesize = 15,
            markers_legend_margin = (26, 10, 0, 0),
            markers_legend_colgap = 4,
            markers_row_gap = 4,
            triple_colorbar_labelsize = 18,
            triple_colorbar_ticklabelsize = 10,
            triple_colorbar_height = 175,
            triple_topo_size = 170,
            triple_topo_rowgap = -36,
            triple_topo_colgap = -58,
            panel_label_padding = (10, 0, 12, 0),
            header_padding = (0, 0, 10, 0),
            title_gap = 12,
            header_span = 1:2,
            root_colgap = 12,
            root_rowgap = 10,
            hop_axis_labelsize = 18,
            hop_colorbar_labelsize = 18,
            hop_colorbar_ticklabelsize = 12,
            hop_colorbar_height = 220,
        )
    elseif layout_mode == :page_landscape_2row
        return (
            adjacent_colorbar_labelsize = 16,
            adjacent_colorbar_ticklabelsize = 10,
            adjacent_colorbar_width = 112,
            adjacent_axis_labelsize = 16,
            bivariate_topo_size = 190,
            bivariate_colorbox_size = 82,
            bivariate_axis_labelsize = 12,
            bivariate_axis_ticklabelsize = 9,
            bivariate_colorbox_gap = 6,
            markers_axis_labelsize = 16,
            markers_colorbar_labelsize = 16,
            markers_colorbar_ticklabelsize = 10,
            markers_colorbar_height = 150,
            markers_topo_size = 150,
            markers_legend_labelsize = 11,
            markers_legend_titlesize = 12,
            markers_legend_margin = (14, 6, 0, 0),
            markers_legend_colgap = 3,
            markers_row_gap = 4,
            triple_colorbar_labelsize = 16,
            triple_colorbar_ticklabelsize = 9,
            triple_colorbar_height = 150,
            triple_topo_size = 155,
            triple_topo_rowgap = -28,
            triple_topo_colgap = -46,
            panel_label_padding = (8, 0, 8, 0),
            header_padding = (0, 0, 8, 0),
            title_gap = 10,
            header_span = 1:3,
            root_colgap = 8,
            root_rowgap = 8,
            hop_axis_labelsize = 16,
            hop_colorbar_labelsize = 16,
            hop_colorbar_ticklabelsize = 10,
            hop_colorbar_height = 190,
        )
    elseif layout_mode == :wide
        return (
            adjacent_colorbar_labelsize = 24,
            adjacent_colorbar_ticklabelsize = 18,
            adjacent_colorbar_width = 180,
            adjacent_axis_labelsize = 24,
            bivariate_topo_size = 300,
            bivariate_colorbox_size = 130,
            bivariate_axis_labelsize = 16,
            bivariate_axis_ticklabelsize = 12,
            bivariate_colorbox_gap = 5,
            markers_axis_labelsize = 24,
            markers_colorbar_labelsize = 24,
            markers_colorbar_ticklabelsize = 18,
            markers_colorbar_height = 220,
            markers_topo_size = 220,
            markers_legend_labelsize = 18,
            markers_legend_titlesize = 20,
            markers_legend_margin = (24, 10, 0, 0),
            markers_legend_colgap = 5,
            markers_row_gap = -10,
            triple_colorbar_labelsize = 24,
            triple_colorbar_ticklabelsize = 12,
            triple_colorbar_height = 240,
            triple_topo_size = 220,
            triple_topo_rowgap = -50,
            triple_topo_colgap = -90,
            panel_label_padding = (20, -15, 20, 0),
            header_padding = (0, 0, 18, 0),
            title_gap = 18,
            header_span = 1:3,
            root_colgap = 12,
            root_rowgap = 14,
            hop_axis_labelsize = 24,
            hop_colorbar_labelsize = 24,
            hop_colorbar_ticklabelsize = 18,
            hop_colorbar_height = 280,
        )
    else
        error("Unknown layout_mode=$(repr(layout_mode)).")
    end
end

function plot_combined_uncerts(
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    corner_colorbox = _colorbox_corner_teuling3,
    range_colorbox = nothing,
    enable_contour = true,
    colorrange_mode = :diverging_balanced,
    uncert_label = "Standard deviation",
    BG = RGBf(0.98, 0.98, 0.98),
    figure_size = (1700, 1000),
    figure_padding = (20, 20, 20, 50),
    layout_mode = :wide,
    panel_label_fontsize = 26,
    include_hop = false,
    return_hop = false,
    hop_n_boot = 20,
    hop_rng = nothing,
    triple_topo_size = nothing,
    triple_colorbar_gap = nothing,
)
    return_hop && !include_hop && error("`return_hop = true` requires `include_hop = true`.")

    f = Figure(backgroundcolor = BG, size = figure_size, figure_padding = figure_padding)
    style = _combined_uncerts_layout_style(layout_mode)
    triple_topo_rowgap = style.triple_topo_rowgap
    triple_topo_colgap = style.triple_topo_colgap

    ga = gb = gc = gd = ge = gh = nothing

    if layout_mode == :wide || layout_mode == :page_landscape_2row
        ga = f[1, 1] = GridLayout()
        gb = f[1, 2] = GridLayout()
        gc = f[1, 3] = GridLayout()
        gd = f[2, 1] = GridLayout()
        if include_hop
            ge = f[2, 2] = GridLayout()
            gh = f[2, 3] = GridLayout()
            triple_topo_rowgap -= layout_mode == :wide ? 30 : 16
            triple_topo_colgap -= layout_mode == :wide ? 28 : 16
        else
            ge = f[2, 2:3] = GridLayout()
        end
    elseif layout_mode == :page_landscape
        ga = f[1, 1] = GridLayout()
        gb = f[1, 2] = GridLayout()
        gc = f[2, 1] = GridLayout()
        gd = f[2, 2] = GridLayout()
        ge = f[3, 1:2] = GridLayout()
        include_hop && (gh = f[4, 1:2] = GridLayout())
    else
        error("Unknown layout_mode=$(repr(layout_mode)).")
    end

    colgap!(f.layout, style.root_colgap)
    rowgap!(f.layout, style.root_rowgap)
    common = (; positions, labels, uncert_label)

    plot_adjacent!(
        ga,
        vec_estimate,
        vec_uncert;
        common...,
        enable_contour = enable_contour,
        BG = BG,
        colorrange_mode = colorrange_mode,
        colorbar_labelsize = style.adjacent_colorbar_labelsize,
        colorbar_ticklabelsize = style.adjacent_colorbar_ticklabelsize,
        colorbar_width = style.adjacent_colorbar_width,
        axis_labelsize = style.adjacent_axis_labelsize,
    )
    plot_bivariate_corner!(
        gb,
        vec_estimate,
        vec_uncert;
        common...,
        colorrange_mode = colorrange_mode,
        colorbox = corner_colorbox,
        topo_size = style.bivariate_topo_size,
        colorbox_size = style.bivariate_colorbox_size,
        axis_labelsize = style.bivariate_axis_labelsize,
        axis_ticklabelsize = style.bivariate_axis_ticklabelsize,
        colorbox_gap = style.bivariate_colorbox_gap,
        hatch = true,
        BG = BG,
    )
    plot_bivariate_range!(
        gc,
        vec_estimate,
        vec_uncert;
        common...,
        order_vertical = :low_to_high,
        enable_contour = enable_contour,
        colorrange_mode = colorrange_mode,
        colorbox = range_colorbox,
        topo_size = style.bivariate_topo_size,
        colorbox_size = style.bivariate_colorbox_size,
        axis_labelsize = style.bivariate_axis_labelsize,
        axis_ticklabelsize = style.bivariate_axis_ticklabelsize,
        colorbox_gap = style.bivariate_colorbox_gap,
        hatch = true,
        BG = BG,
    )
    plot_uncert_markers!(
        gd,
        vec_estimate,
        vec_uncert;
        common...,
        enable_contour = enable_contour,
        BG = BG,
        colorrange_mode = colorrange_mode,
        axis_labelsize = style.markers_axis_labelsize,
        colorbar_labelsize = style.markers_colorbar_labelsize,
        colorbar_ticklabelsize = style.markers_colorbar_ticklabelsize,
        colorbar_height = style.triple_colorbar_height,
        legend_labelsize = style.markers_legend_labelsize,
        legend_titlesize = style.markers_legend_titlesize,
        legend_margin = style.markers_legend_margin,
        legend_colgap = style.markers_legend_colgap,
        row_gap = style.markers_row_gap,
    )
    plot_triple_CI!(
        ge,
        vec_estimate,
        vec_uncert;
        common...,
        BG = BG,
        colorrange_mode = colorrange_mode,
        enable_contour = false,
        colorbar_labelsize = style.triple_colorbar_labelsize,
        colorbar_ticklabelsize = style.markers_colorbar_ticklabelsize,
        colorbar_height = style.triple_colorbar_height,
        colorbar_gap = triple_colorbar_gap,
        topo_rowgap = triple_topo_rowgap,
        topo_colgap = triple_topo_colgap,
        topo_size = triple_topo_size,
    )

    hop_obs = hop_boot_means = nothing
    if include_hop
        hop_obs, hop_boot_means = plot_HOP!(
            gh,
            vec_estimate,
            vec_uncert;
            common...,
            n_boot = hop_n_boot,
            rng = hop_rng,
            BG = BG,
            uncert_label = uncert_label,
            colorrange_mode = colorrange_mode,
            axis_labelsize = style.hop_axis_labelsize,
            colorbar_labelsize = style.hop_colorbar_labelsize,
            colorbar_ticklabelsize = style.markers_colorbar_ticklabelsize,
            colorbar_height = style.triple_colorbar_height,
        )
    end

    labs = [
        "A. Adjacent",
        "B. Bivariate corners",
        "C. Bivariate range",
        "D. Marker size change",
        "E. Confidence intervals",
    ]
    lays = [ga, gb, gc, gd, ge]

    if include_hop
        push!(labs, "F. Hypothetical Outcome Plots")
        push!(lays, gh)
    end

    for (lab, lay) in zip(labs, lays)
        Label(
            lay[1, 1, TopLeft()],
            lab;
            fontsize = panel_label_fontsize,
            font = :bold,
            padding = style.panel_label_padding,
            halign = :left,
            tellwidth = false,
            tellheight = false,
        )
    end

    return return_hop ? (; figure = f, hop_obs = hop_obs, hop_boot_means = hop_boot_means) :
           f
end

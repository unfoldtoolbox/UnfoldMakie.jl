# Helpers for aligning saved/selectable region polygons to the same
# displayed head domain that Makie topoplots use.

@isdefined(load_erp_subject_avgref_or_nothing) ||
    include(joinpath(@__DIR__, "..", "region_detection", "rereferencing.jl"))

function preview_limits(domain::TopoplotDomain, cfg::RegionGrid64Config)
    xmin, xmax, ymin, ymax = domain.bbox
    pad = cfg.preview_padding
    return (xmin - pad, xmax + pad, ymin - pad, ymax + pad)
end

function topoplot_display_domain(labels, cfg::RegionGrid64Config)
    tmpfig = Figure(size = (10, 10))
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(
        tmpax,
        zeros(Float32, length(labels));
        labels = labels,
        contours = false,
        clip = false,
        label_scatter = false,
        label_text = false,
    )
    topoplot_domain_from_plot(h, cfg)
end

function display_aligned_layout(layout::RegionLayout64, cfg::RegionGrid64Config; alignment_labels)
    display_domain = topoplot_display_domain(alignment_labels, cfg)
    display_cells = [
        map_polygon_between_domains(cell, layout.domain, display_domain) for cell in layout.cells
    ]
    display_metrics = build_metrics(display_cells)
    display_radius = domain_mask_radius(display_domain)

    aligned_regions = [
        let
            poly = display_cells[idx]
            template_poly = [
                head_to_template(
                    p;
                    template_center = cfg.template_center,
                    template_radius = cfg.template_radius,
                    head_center = (display_domain.center[1], display_domain.center[2]),
                    head_radius = display_radius,
                ) for p in poly
            ]
            (
                label = region.label,
                points = join([@sprintf("%.3f,%.3f", p[1], p[2]) for p in template_poly], " "),
                polygon = poly,
                center = display_metrics.centroids[idx],
                template_center = head_to_template(
                    display_metrics.centroids[idx];
                    template_center = cfg.template_center,
                    template_radius = cfg.template_radius,
                    head_center = (display_domain.center[1], display_domain.center[2]),
                    head_radius = display_radius,
                ),
                area = display_metrics.areas[idx],
                compactness = display_metrics.compactness[idx],
            )
        end for (idx, region) in enumerate(layout.regions)
    ]

    RegionLayout64(
        name = layout.name,
        title = layout.title,
        domain = display_domain,
        seeds = layout.seeds,
        weights = layout.weights,
        cells = display_cells,
        metrics = display_metrics,
        regions = aligned_regions,
    )
end

function point_segment_distance(p::Point2f, a::Point2f, b::Point2f)
    abx = Float64(b[1] - a[1])
    aby = Float64(b[2] - a[2])
    apx = Float64(p[1] - a[1])
    apy = Float64(p[2] - a[2])
    denom = abx^2 + aby^2
    denom <= 1.0e-12 && return hypot(apx, apy)
    t = clamp((apx * abx + apy * aby) / denom, 0.0, 1.0)
    qx = Float64(a[1]) + t * abx
    qy = Float64(a[2]) + t * aby
    hypot(Float64(p[1]) - qx, Float64(p[2]) - qy)
end

function polygon_boundary_distance(p::Point2f, poly)
    n = length(poly)
    n < 2 && return Inf
    minimum(
        point_segment_distance(p, poly[idx], poly[idx == n ? 1 : idx + 1])
        for idx in 1:n
    )
end

function edge_on_outer_boundary(p::Point2f, q::Point2f, boundary_poly; atol = 1.0e-3)
    midpoint = pt(0.5f0 * (p[1] + q[1]), 0.5f0 * (p[2] + q[2]))
    polygon_boundary_distance(p, boundary_poly) <= atol &&
        polygon_boundary_distance(q, boundary_poly) <= atol &&
        polygon_boundary_distance(midpoint, boundary_poly) <= atol
end

# Tiny adapter: the grid code only needs labels, avgref signal, and avgref |t|.
function grid_avgref_columns(subject_data)
    (
        labels = String.(subject_data.labels),
        estimate_avgref = avgref_signal(subject_data),
        abs_t_avgref = avgref_abs_t(subject_data),
    )
end

function load_grid_avgref_case_or_nothing(cfg::RegionGrid64Config)
    subject_data = load_erp_subject_avgref_or_nothing(
        cfg.pipeline_task;
        subject = cfg.pipeline_subject,
        timepoint = cfg.pipeline_timepoint,
        condition = cfg.pipeline_condition,
    )
    isnothing(subject_data) && return nothing
    grid_avgref_columns(subject_data)
end

function partition_alignment_labels(cfg::RegionGrid64Config; fallback = nothing)
    subject_data = load_grid_avgref_case_or_nothing(cfg)
    isnothing(subject_data) ? fallback : subject_data.labels
end

function overlay_electrode_layout!(
    ax,
    labels;
    color = RGBAf(0, 0, 0, 0.88),
    strokecolor = :white,
    strokewidth = 0.7,
    markersize = 9,
)
    positions = TopoPlots.labels2positions(labels)
    xs = Float32[p[1] for p in positions]
    ys = Float32[p[2] for p in positions]
    scatter!(
        ax,
        xs,
        ys;
        color = color,
        strokecolor = strokecolor,
        strokewidth = strokewidth,
        markersize = markersize,
    )
end

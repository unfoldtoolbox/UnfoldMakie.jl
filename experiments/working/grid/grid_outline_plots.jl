# Helpers for human-facing outline previews and SoSci overlay diagnostics.

# Return square limits centered on the head that leave padding for the full outline.
function clean_outline_limits(center::Point2f, radius; pad_fraction = 0.05f0)
    parts = pipeline_head_outline_parts(center, radius)
    pts = vcat(parts.circle, parts.nose, parts.left_ear, parts.right_ear)
    half_span = maximum(max(abs(p[1] - center[1]), abs(p[2] - center[2])) for p in pts)
    padded = Float32(half_span * (1 + pad_fraction))
    return (
        center[1] - padded,
        center[1] + padded,
        center[2] - padded,
        center[2] + padded,
    )
end

# Return square limits for the clean outline export using the existing head domain.
clean_outline_limits(domain::TopoplotDomain; pad_fraction = 0.05f0) =
    clean_outline_limits(domain.center, domain_mask_radius(domain); pad_fraction = pad_fraction)

# Draw only the internal region boundaries once so shared edges stay visually thin.
function draw_region_boundaries!(
    ax,
    layout::RegionLayout64;
    color = RGBAf(0, 0, 0, 1),
    linewidth = 0.8,
    display_domain = nothing,
)
    domain = isnothing(display_domain) ? layout.domain : display_domain
    cells = isnothing(display_domain) ? layout.cells : [
        map_polygon_between_domains(cell, layout.domain, display_domain) for cell in layout.cells
    ]
    counts, _ = _polygon_edge_inventory(cells)
    drawn = Set{Tuple{Tuple{Int,Int},Tuple{Int,Int}}}()
    boundary_tol = max(2.0e-2, 2.0e-2 * Float64(domain_mask_radius(domain)))

    for poly in cells
        n = length(poly)
        n < 2 && continue
        for idx in 1:n
            p = poly[idx]
            q = poly[idx == n ? 1 : idx + 1]
            key = _edge_key(p, q)
            key in drawn && continue
            if get(counts, key, 0) == 1 && edge_on_outer_boundary(p, q, domain.polygon; atol = boundary_tol)
                continue
            end
            lines!(ax, [p[1], q[1]], [p[2], q[2]]; color = color, linewidth = linewidth)
            push!(drawn, key)
        end
    end
    return ax
end

# Render a clean head-and-boundaries export for the existing 64-region partition.
function clean_partition_outline_figure(
    layout::RegionLayout64,
    cfg::RegionGrid64Config;
    pixels = 1024,
    pad_fraction = 0.05f0,
    head_linewidth = 2.0,
    region_linewidth = 1.15,
    electrode_labels = nothing,
    alignment_labels = nothing,
    display_domain_override = nothing,
    electrode_color = RGBAf(0, 0, 0, 0.88),
    electrode_strokecolor = :white,
    electrode_strokewidth = 0.7,
    electrode_markersize = 12,
)
    fig = Figure(size = (pixels, pixels), backgroundcolor = :white)
    ax = Axis(fig[1, 1]; aspect = DataAspect(), backgroundcolor = :white)
    hidedecorations!(ax)
    hidespines!(ax)
    domain_labels = isnothing(alignment_labels) ?
        partition_alignment_labels(cfg; fallback = electrode_labels) :
        alignment_labels
    display_domain = isnothing(display_domain_override) ?
        (isnothing(domain_labels) ? layout.domain : topoplot_display_domain(domain_labels, cfg)) :
        display_domain_override
    limits!(ax, clean_outline_limits(display_domain; pad_fraction = pad_fraction)...)
    draw_region_boundaries!(ax, layout; color = RGBAf(0, 0, 0, 1), linewidth = region_linewidth, display_domain = display_domain)
    draw_pipeline_head_outline!(ax, display_domain.center, domain_mask_radius(display_domain); color = :black, linewidth = head_linewidth)
    if !isnothing(electrode_labels)
        overlay_electrode_layout!(
            ax,
            electrode_labels;
            color = electrode_color,
            strokecolor = electrode_strokecolor,
            strokewidth = electrode_strokewidth,
            markersize = electrode_markersize,
        )
    end
    return fig
end

# Save the clean head-and-boundaries export under the target-stimuli folder.
function save_clean_partition_outline(
    layout::RegionLayout64,
    cfg::RegionGrid64Config;
    filepath = joinpath("experiments", "target stimuli", "task2_region_grid64_outline.png"),
    pixels = 1024,
    pad_fraction = 0.05f0,
    head_linewidth = 2.0,
    region_linewidth = 1.15,
    electrode_labels = nothing,
    alignment_labels = nothing,
    display_domain_override = nothing,
    electrode_color = RGBAf(0, 0, 0, 0.88),
    electrode_strokecolor = :white,
    electrode_strokewidth = 0.7,
    electrode_markersize = 12,
)
    fig = clean_partition_outline_figure(
        layout,
        cfg;
        pixels = pixels,
        pad_fraction = pad_fraction,
        head_linewidth = head_linewidth,
        region_linewidth = region_linewidth,
        electrode_labels = electrode_labels,
        alignment_labels = alignment_labels,
        display_domain_override = display_domain_override,
        electrode_color = electrode_color,
        electrode_strokecolor = electrode_strokecolor,
        electrode_strokewidth = electrode_strokewidth,
        electrode_markersize = electrode_markersize,
    )
    mkpath(dirname(filepath))
    save(filepath, fig)
    return filepath
end

# Overlay the montage28-aligned outline and the current SoSci/PHP polygons to spot coordinate mismatches.
function montage28_sosci_overlay_figure(
    layout::RegionLayout64,
    cfg::RegionGrid64Config;
    alignment_labels,
    selectable_layout = layout,
    electrode_labels = alignment_labels,
    pixels = 1024,
    pad_fraction = 0.05f0,
    head_linewidth = 2.0,
    montage_color = RGBAf(0, 0, 0, 0.95),
    selectable_color = RGBAf(0.86, 0.16, 0.16, 0.82),
    montage_linewidth = 1.25,
    selectable_linewidth = 1.05,
)
    aligned_layout = display_aligned_layout(layout, cfg; alignment_labels = alignment_labels)

    fig = Figure(size = (pixels, pixels + 96), backgroundcolor = :white)
    Label(
        fig[1, 1],
        "Overlay check for task2_region_grid64_montage28";
        fontsize = 20,
        font = :bold,
    )

    ax = Axis(fig[2, 1]; aspect = DataAspect(), backgroundcolor = :white)
    hidedecorations!(ax)
    hidespines!(ax)
    limits!(ax, clean_outline_limits(aligned_layout.domain; pad_fraction = pad_fraction)...)

    draw_region_boundaries!(ax, aligned_layout; color = montage_color, linewidth = montage_linewidth)
    draw_pipeline_head_outline!(
        ax,
        aligned_layout.domain.center,
        domain_mask_radius(aligned_layout.domain);
        color = montage_color,
        linewidth = head_linewidth,
    )

    draw_region_boundaries!(ax, selectable_layout; color = selectable_color, linewidth = selectable_linewidth)
    draw_pipeline_head_outline!(
        ax,
        selectable_layout.domain.center,
        domain_mask_radius(selectable_layout.domain);
        color = selectable_color,
        linewidth = max(0.9, head_linewidth - 0.5),
    )

    if !isnothing(electrode_labels)
        overlay_electrode_layout!(
            ax,
            electrode_labels;
            color = RGBAf(0, 0, 0, 0.55),
            strokecolor = :white,
            strokewidth = 0.65,
            markersize = 10,
        )
    end

    Label(
        fig[3, 1],
        "Black = fig_64_count_search_outline_montage28 | Red = current SoSci/PHP polygons";
        fontsize = 16,
    )
    rowsize!(fig.layout, 1, Fixed(40))
    rowsize!(fig.layout, 3, Fixed(36))
    rowgap!(fig.layout, 8)
    return fig
end

function save_montage28_sosci_overlay(
    layout::RegionLayout64,
    cfg::RegionGrid64Config;
    filepath = joinpath("experiments", "target stimuli", "task2_region_grid64_montage28_sosci_overlay.png"),
    alignment_labels,
    selectable_layout = layout,
    electrode_labels = alignment_labels,
    pixels = 1024,
    pad_fraction = 0.05f0,
    head_linewidth = 2.0,
    montage_color = RGBAf(0, 0, 0, 0.95),
    selectable_color = RGBAf(0.86, 0.16, 0.16, 0.82),
    montage_linewidth = 1.25,
    selectable_linewidth = 1.05,
)
    fig = montage28_sosci_overlay_figure(
        layout,
        cfg;
        alignment_labels = alignment_labels,
        selectable_layout = selectable_layout,
        electrode_labels = electrode_labels,
        pixels = pixels,
        pad_fraction = pad_fraction,
        head_linewidth = head_linewidth,
        montage_color = montage_color,
        selectable_color = selectable_color,
        montage_linewidth = montage_linewidth,
        selectable_linewidth = selectable_linewidth,
    )
    mkpath(dirname(filepath))
    save(filepath, fig)
    return filepath
end

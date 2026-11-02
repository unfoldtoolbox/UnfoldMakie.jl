# Layout construction and optimization helpers for the 64-region grid.

function extract_topoplot_domain(cfg::RegionGrid64Config)
    labels, _ = UnfoldMakie.example_montage("montage_64")
    fig = Figure(size = (10, 10))
    ax = Axis(fig[1, 1])
    h = TopoPlots.eeg_topoplot!(ax, collect(Float32, 1:length(labels)); labels = labels)
    return topoplot_domain_from_plot(h, cfg)
end

function regular_ring_angles(n::Integer, ring_index::Integer)
    offset = isodd(ring_index) ? π / n : 0.0
    return [offset + 2π * (k - 1) / n for k in 1:n]
end

function ring_seed_radii(domain::TopoplotDomain, counts)
    counts_sum = sum(counts)
    bounds = zeros(Float64, length(counts) + 1)
    cumulative = 0
    for (idx, count) in enumerate(counts)
        cumulative += count
        bounds[idx + 1] = domain.equivalent_radius * sqrt(cumulative / counts_sum)
    end

    return [
        sqrt((bounds[idx]^2 + bounds[idx + 1]^2) / 2) for idx in eachindex(counts)
    ]
end

function radial_seeds(domain::TopoplotDomain, cfg::RegionGrid64Config)
    seeds = Point2f[]
    radii = ring_seed_radii(domain, cfg.radial_counts)

    for (ring_index, (count, radius)) in enumerate(zip(cfg.radial_counts, radii))
        frac = radius / domain.equivalent_radius
        for θ in regular_ring_angles(count, ring_index)
            boundary_r = ray_boundary_radius(domain.xg, domain.yg, domain.mask, domain.center, θ)
            push!(
                seeds,
                pt(
                    domain.center[1] + frac * boundary_r * cos(θ),
                    domain.center[2] + frac * boundary_r * sin(θ),
                ),
            )
        end
    end

    return seeds
end

function random_seeds(domain::TopoplotDomain, n::Int; rng = MersenneTwister(64))
    xmin, xmax, ymin, ymax = domain.bbox
    seeds = Point2f[]
    while length(seeds) < n
        candidate = pt(rand(rng) * (xmax - xmin) + xmin, rand(rng) * (ymax - ymin) + ymin)
        point_in_polygon(candidate[1], candidate[2], domain.polygon) || continue
        push!(seeds, candidate)
    end
    return seeds
end

function power_cell(domain_poly, seeds, weights, idx)
    poly = copy(domain_poly)
    si = seeds[idx]
    wi = weights[idx]

    for j in eachindex(seeds)
        j == idx && continue
        sj = seeds[j]
        wj = weights[j]
        a = 2 * (sj[1] - si[1])
        b = 2 * (sj[2] - si[2])
        c = (sj[1]^2 + sj[2]^2) - (si[1]^2 + si[2]^2) + wi - wj
        poly = clip_polygon_halfplane(poly, a, b, c)
        isempty(poly) && break
    end

    return poly
end

function power_cells(domain_poly, seeds, weights)
    return [power_cell(domain_poly, seeds, weights, idx) for idx in eachindex(seeds)]
end

function build_metrics(cells)
    areas = Float64[polygon_area(cell) for cell in cells]
    centroids = Point2f[polygon_centroid(cell) for cell in cells]
    compactness = Float64[polygon_compactness(cell) for cell in cells]
    valid = filter(>(0.0), areas)
    area_mean = isempty(valid) ? NaN : mean(valid)
    area_cv = isempty(valid) ? NaN : std(valid) / max(area_mean, eps(Float64))
    return (
        areas = areas,
        centroids = centroids,
        compactness = compactness,
        min_area = isempty(valid) ? 0.0 : minimum(valid),
        max_area = isempty(valid) ? 0.0 : maximum(valid),
        area_mean = area_mean,
        area_cv = area_cv,
        min_compactness = isempty(compactness) ? 0.0 : minimum(compactness),
        mean_compactness = isempty(compactness) ? 0.0 : mean(compactness),
    )
end

function blend_seed(a::Point2f, b::Point2f, frac)
    return pt((1 - frac) * a[1] + frac * b[1], (1 - frac) * a[2] + frac * b[2])
end

function centroidal_voronoi_layout(domain::TopoplotDomain, init_seeds, cfg::RegionGrid64Config)
    seeds = copy(init_seeds)
    weights = zeros(Float64, length(seeds))
    cells = power_cells(domain.polygon, seeds, weights)

    for _ in 1:cfg.centroidal_iterations
        metrics = build_metrics(cells)
        new_seeds = copy(seeds)
        for idx in eachindex(seeds)
            metrics.areas[idx] <= 1.0e-8 && continue
            new_seeds[idx] = blend_seed(seeds[idx], metrics.centroids[idx], cfg.centroidal_move_fraction)
        end
        seeds = new_seeds
        cells = power_cells(domain.polygon, seeds, weights)
    end

    return seeds, weights, cells
end

function balanced_weights(domain::TopoplotDomain, seeds, weights, cfg::RegionGrid64Config)
    target_area = domain.area / length(seeds)
    scale = cfg.capacity_step * domain.equivalent_radius^2
    cells = power_cells(domain.polygon, seeds, weights)

    for iter in 1:cfg.capacity_inner_iterations
        metrics = build_metrics(cells)
        err = target_area .- metrics.areas
        max_rel_err = maximum(abs.(err)) / target_area
        max_rel_err <= cfg.area_tolerance && return weights, cells

        step = scale / sqrt(iter)
        weights .+= step .* (err ./ target_area)
        weights .-= mean(weights)
        cells = power_cells(domain.polygon, seeds, weights)
    end

    return weights, cells
end

function capacity_constrained_layout(domain::TopoplotDomain, init_seeds, cfg::RegionGrid64Config)
    seeds = copy(init_seeds)
    weights = zeros(Float64, length(seeds))
    best = nothing

    for _ in 1:cfg.capacity_outer_iterations
        weights, cells = balanced_weights(domain, seeds, weights, cfg)
        metrics = build_metrics(cells)
        movement = mean(hypot(metrics.centroids[idx][1] - seeds[idx][1], metrics.centroids[idx][2] - seeds[idx][2]) for idx in eachindex(seeds))

        if isnothing(best) || metrics.area_cv < best.metrics.area_cv
            best = (; seeds = copy(seeds), weights = copy(weights), cells = deepcopy(cells), metrics)
        end

        movement <= cfg.movement_tolerance && metrics.area_cv <= cfg.area_tolerance && break

        new_seeds = copy(seeds)
        for idx in eachindex(seeds)
            metrics.areas[idx] <= 1.0e-8 && continue
            new_seeds[idx] = blend_seed(seeds[idx], metrics.centroids[idx], cfg.capacity_move_fraction)
        end
        seeds = new_seeds
    end

    final_weights, final_cells = balanced_weights(domain, seeds, weights, cfg)
    final_metrics = build_metrics(final_cells)
    if !isnothing(best) && best.metrics.area_cv < final_metrics.area_cv
        return best.seeds, best.weights, best.cells
    end
    return seeds, final_weights, final_cells
end

function max_export_head_radius(cells, cfg::RegionGrid64Config)
    cx, cy = cfg.parser_head_center
    radii = Float64[hypot(p[1] - cx, p[2] - cy) for cell in cells for p in cell]
    isempty(radii) && return Float32(cfg.parser_head_radius)
    return Float32(maximum(radii))
end

function template_polygon(cell, cfg::RegionGrid64Config, export_head_radius)
    return Point2f[
        head_to_template(
            p;
            template_center = cfg.template_center,
            template_radius = cfg.template_radius,
            head_center = cfg.parser_head_center,
            head_radius = export_head_radius,
        ) for p in cell
    ]
end

function polygon_points_string(poly; digits = 3)
    return join((@sprintf("%.*f,%.*f", digits, p[1], digits, p[2]) for p in poly), " ")
end

function build_regions(cells, metrics, cfg::RegionGrid64Config)
    export_head_radius = max_export_head_radius(cells, cfg)
    template_centroids = Point2f[
        head_to_template(
            metrics.centroids[idx];
            template_center = cfg.template_center,
            template_radius = cfg.template_radius,
            head_center = cfg.parser_head_center,
            head_radius = export_head_radius,
        ) for idx in eachindex(cells)
    ]

    perm = sortperm(
        eachindex(cells);
        by = idx -> (
            round(Float64(template_centroids[idx][2]); digits = 4),
            round(Float64(template_centroids[idx][1]); digits = 4),
        ),
    )

    return [
        (
            label = @sprintf("R%02d", order),
            points = polygon_points_string(template_polygon(cells[idx], cfg, export_head_radius); digits = cfg.digits),
            polygon = cells[idx],
            center = metrics.centroids[idx],
            template_center = template_centroids[idx],
            area = metrics.areas[idx],
            compactness = metrics.compactness[idx],
        ) for (order, idx) in enumerate(perm)
    ]
end

function make_layout(name::Symbol, title::String, domain, seeds, weights, cells, cfg)
    metrics = build_metrics(cells)
    regions = build_regions(cells, metrics, cfg)
    return RegionLayout64(; name, title, domain, seeds, weights, cells, metrics, regions)
end

function layout_is_ugly(layout::RegionLayout64)
    target_area = layout.domain.area / length(layout.cells)
    return layout.metrics.min_area < 0.55 * target_area || layout.metrics.min_compactness < 0.18
end

function variant_layouts(cfg::RegionGrid64Config)
    domain = extract_topoplot_domain(cfg)
    random_init = random_seeds(domain, sum(cfg.radial_counts); rng = MersenneTwister(cfg.random_seed))
    radial_init = radial_seeds(domain, cfg)

    a_layout = let
        seeds = random_init
        weights = zeros(Float64, length(seeds))
        cells = power_cells(domain.polygon, seeds, weights)
        make_layout(:A, "A. Random Voronoi", domain, seeds, weights, cells, cfg)
    end

    b_layout = let
        seeds, weights, cells = centroidal_voronoi_layout(domain, radial_init, cfg)
        make_layout(:B, "B. Centroidal Voronoi", domain, seeds, weights, cells, cfg)
    end

    c_layout = let
        seeds, weights, cells = capacity_constrained_layout(domain, radial_init, cfg)
        make_layout(:C, "C. Equal-Area Power Diagram", domain, seeds, weights, cells, cfg)
    end

    final_layout = layout_is_ugly(c_layout) ? b_layout : c_layout
    return (; domain, A = a_layout, B = b_layout, C = c_layout, final = final_layout)
end

function build_task2_region_grid64(; kwargs...)
    cfg = RegionGrid64Config(; kwargs...)
    layouts = variant_layouts(cfg)
    return (; config = cfg, layouts)
end

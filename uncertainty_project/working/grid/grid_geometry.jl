# Polygon and head-domain geometry helpers used by the 64-region grid workflow.

point_xy(p) = (Float64(p[1]), Float64(p[2]))
pt(x, y) = Point2f(Float32(x), Float32(y))

function head_to_template(
    x,
    y;
    template_center = (150.0f0, 150.0f0),
    template_radius = 126.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
)
    tx = template_center[1] + template_radius * (x - head_center[1]) / head_radius
    ty = template_center[2] - template_radius * (y - head_center[2]) / head_radius
    return Point2f(Float32(tx), Float32(ty))
end

head_to_template(p::Point2f; kwargs...) = head_to_template(p[1], p[2]; kwargs...)

function polygon_signed_area(poly)
    n = length(poly)
    n < 3 && return 0.0
    area2 = 0.0
    @inbounds for i in 1:n
        j = i == n ? 1 : i + 1
        xi, yi = point_xy(poly[i])
        xj, yj = point_xy(poly[j])
        area2 += xi * yj - xj * yi
    end
    return 0.5 * area2
end

polygon_area(poly) = abs(polygon_signed_area(poly))

function polygon_centroid(poly)
    n = length(poly)
    n == 0 && return Point2f(0, 0)
    n < 3 && return Point2f(mean(Float32[p[1] for p in poly]), mean(Float32[p[2] for p in poly]))

    area6 = 0.0
    cx = 0.0
    cy = 0.0
    @inbounds for i in 1:n
        j = i == n ? 1 : i + 1
        xi, yi = point_xy(poly[i])
        xj, yj = point_xy(poly[j])
        cross = xi * yj - xj * yi
        area6 += cross
        cx += (xi + xj) * cross
        cy += (yi + yj) * cross
    end

    if abs(area6) < 1.0e-10
        return Point2f(mean(Float32[p[1] for p in poly]), mean(Float32[p[2] for p in poly]))
    end

    scale = 1 / (3 * area6)
    return Point2f(Float32(cx * scale), Float32(cy * scale))
end

function polygon_perimeter(poly)
    n = length(poly)
    n < 2 && return 0.0
    perim = 0.0
    @inbounds for i in 1:n
        j = i == n ? 1 : i + 1
        perim += hypot(poly[j][1] - poly[i][1], poly[j][2] - poly[i][2])
    end
    return perim
end

function polygon_compactness(poly)
    area = polygon_area(poly)
    perim = polygon_perimeter(poly)
    (area <= 0 || perim <= 0) && return 0.0
    return 4π * area / (perim^2)
end

function clean_polygon(poly; atol = 1.0e-5)
    isempty(poly) && return Point2f[]

    pts = Point2f[]
    for p in poly
        if isempty(pts) || hypot(p[1] - pts[end][1], p[2] - pts[end][2]) > atol
            push!(pts, Point2f(p))
        end
    end

    if length(pts) > 1 && hypot(pts[1][1] - pts[end][1], pts[1][2] - pts[end][2]) <= atol
        pop!(pts)
    end

    changed = true
    while changed && length(pts) >= 3
        changed = false
        keep = trues(length(pts))
        for i in eachindex(pts)
            i_prev = i == 1 ? length(pts) : i - 1
            i_next = i == length(pts) ? 1 : i + 1
            a = pts[i_prev]
            b = pts[i]
            c = pts[i_next]
            bax = Float64(b[1] - a[1])
            bay = Float64(b[2] - a[2])
            cbx = Float64(c[1] - b[1])
            cby = Float64(c[2] - b[2])
            cross = abs(bax * cby - bay * cbx)
            if cross <= atol
                keep[i] = false
                changed = true
            end
        end
        pts = pts[keep]
    end

    return pts
end

function clip_polygon_halfplane(poly, a, b, c; atol = 1.0e-7)
    isempty(poly) && return Point2f[]
    out = Point2f[]
    n = length(poly)

    for i in 1:n
        p = poly[i]
        q = poly[i == n ? 1 : i + 1]
        fp = a * p[1] + b * p[2] - c
        fq = a * q[1] + b * q[2] - c
        inside_p = fp <= atol
        inside_q = fq <= atol

        if inside_p && inside_q
            push!(out, q)
        elseif inside_p && !inside_q
            t = fp / (fp - fq)
            push!(out, pt(p[1] + t * (q[1] - p[1]), p[2] + t * (q[2] - p[2])))
        elseif !inside_p && inside_q
            t = fp / (fp - fq)
            push!(out, pt(p[1] + t * (q[1] - p[1]), p[2] + t * (q[2] - p[2])))
            push!(out, q)
        end
    end

    return clean_polygon(out)
end

function clip_polygon_convex(poly, clipper; atol = 1.0e-7)
    out = copy(poly)
    isempty(out) && return Point2f[]
    m = length(clipper)

    for i in 1:m
        p = clipper[i]
        q = clipper[i == m ? 1 : i + 1]
        ex = q[1] - p[1]
        ey = q[2] - p[2]
        a = ey
        b = -ex
        c = ey * p[1] - ex * p[2]
        out = clip_polygon_halfplane(out, a, b, c; atol = atol)
        isempty(out) && break
    end

    return clean_polygon(out; atol = atol)
end

function mask_centroid(xg, yg, mask)
    xs = Float64[]
    ys = Float64[]
    for j in eachindex(yg), i in eachindex(xg)
        mask[i, j] || continue
        push!(xs, xg[i])
        push!(ys, yg[j])
    end
    return Point2f(Float32(mean(xs)), Float32(mean(ys)))
end

function bilinear_mask_value(x, y, xg, yg, mask)
    if x < first(xg) || x > last(xg) || y < first(yg) || y > last(yg)
        return 0.0
    end

    dx = xg[2] - xg[1]
    dy = yg[2] - yg[1]
    fx = clamp((x - xg[1]) / dx + 1, 1, length(xg) - 1)
    fy = clamp((y - yg[1]) / dy + 1, 1, length(yg) - 1)
    i = clamp(floor(Int, fx), 1, length(xg) - 1)
    j = clamp(floor(Int, fy), 1, length(yg) - 1)
    tx = fx - i
    ty = fy - j

    m11 = mask[i, j] ? 1.0 : 0.0
    m21 = mask[i + 1, j] ? 1.0 : 0.0
    m12 = mask[i, j + 1] ? 1.0 : 0.0
    m22 = mask[i + 1, j + 1] ? 1.0 : 0.0

    return (1 - tx) * (1 - ty) * m11 + tx * (1 - ty) * m21 + (1 - tx) * ty * m12 +
           tx * ty * m22
end

function ray_boundary_radius(xg, yg, mask, center::Point2f, θ; steps = 24)
    dirx = cos(θ)
    diry = sin(θ)
    xmin, xmax = extrema(xg)
    ymin, ymax = extrema(yg)
    max_r = hypot(max(abs(xmin - center[1]), abs(xmax - center[1])), max(abs(ymin - center[2]), abs(ymax - center[2])))

    lo = 0.0
    hi = max_r
    for _ in 1:steps
        mid = (lo + hi) / 2
        x = center[1] + mid * dirx
        y = center[2] + mid * diry
        if bilinear_mask_value(x, y, xg, yg, mask) >= 0.5
            lo = mid
        else
            hi = mid
        end
    end
    return lo
end

function boundary_polygon_from_mask(xg, yg, mask, center::Point2f, n_samples)
    poly = Point2f[]
    for k in 0:(n_samples-1)
        θ = 2π * k / n_samples
        r = ray_boundary_radius(xg, yg, mask, center, θ)
        push!(poly, pt(center[1] + r * cos(θ), center[2] + r * sin(θ)))
    end
    return clean_polygon(poly)
end

function topoplot_domain_from_plot(h, cfg::RegionGrid64Config)
    tp = h.plots[1]
    xg = Float32.(tp.xg[])
    yg = Float32.(tp.yg[])
    mask = BitMatrix(tp.mask[])
    center = mask_centroid(xg, yg, mask)
    polygon = boundary_polygon_from_mask(xg, yg, mask, center, cfg.boundary_samples)
    bbox = (
        minimum(p[1] for p in polygon),
        maximum(p[1] for p in polygon),
        minimum(p[2] for p in polygon),
        maximum(p[2] for p in polygon),
    )
    area = polygon_area(polygon)
    equivalent_radius = sqrt(area / π)
    return TopoplotDomain(; xg, yg, mask, center, polygon, bbox, area, equivalent_radius)
end

domain_mask_radius(domain::TopoplotDomain) = 0.5f0 * (last(domain.xg) - first(domain.xg))

function map_polygon_between_domains(poly, source_domain::TopoplotDomain, target_domain::TopoplotDomain)
    src_center = source_domain.center
    dst_center = target_domain.center
    src_radius = domain_mask_radius(source_domain)
    dst_radius = domain_mask_radius(target_domain)
    scale = dst_radius / src_radius
    return Point2f[
        pt(
            dst_center[1] + scale * (p[1] - src_center[1]),
            dst_center[2] + scale * (p[2] - src_center[2]),
        ) for p in poly
    ]
end

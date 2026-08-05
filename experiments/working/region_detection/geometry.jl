import GeometryBasics

const TOPO_REGIONS_32 = [
    (label = "R01", points = "135,70 136,71 172,62 178,34 165,32 152,31 139,31 126,33"),
    (label = "R02", points = "101,84 135,70 126,33 114,36 102,40 91,46 81,51"),
    (label = "R03", points = "172,62 182,78 210,78 227,57 216,49 203,43 191,38 178,34"),
    (label = "R04", points = "70,104 100,88 101,84 81,51 71,59 61,68 52,78 44,88"),
    (label = "R05", points = "172,62 136,71 148,107 174,103 182,78"),
    (label = "R06", points = "210,78 219,108 228,113 261,97 254,86 246,75 237,66 227,57"),
    (label = "R07", points = "148,107 136,71 135,70 101,84 100,88 116,119 141,116"),
    (label = "R08", points = "210,78 182,78 174,103 189,120 219,108"),
    (label = "R09", points = "107,133 116,119 100,88 70,104 73,130"),
    (label = "R10", points = "64,141 73,130 70,104 44,88 38,99 33,110 29,122 26,135"),
    (label = "R11", points = "189,120 174,103 148,107 141,116 155,149 185,143"),
    (label = "R12", points = "228,113 233,144 238,149 275,142 273,130 270,119 261,97"),
    (label = "R13", points = "219,108 189,120 185,143 197,154 233,144 228,113"),
    (label = "R14", points = "113,161 149,160 155,149 141,116 116,119 107,133"),
    (label = "R15", points = "64,141 69,164 107,170 113,161 107,133 73,130"),
    (label = "R16", points = "60,177 69,164 64,141 26,135 24,158 24,169 26,182"),
    (label = "R17", points = "238,149 239,182 271,192 274,179 276,167 276,155 275,142"),
    (label = "R18", points = "155,149 149,160 158,187 183,190 197,178 197,154 185,143"),
    (label = "R19", points = "197,178 226,191 239,182 238,149 233,144 197,154"),
    (label = "R20", points = "107,170 109,188 129,206 145,203 158,187 149,160 113,161"),
    (label = "R21", points = "60,177 74,207 81,209 109,188 107,170 69,164"),
    (label = "R22", points = "74,207 60,177 26,182 29,194 33,206 38,217 45,227"),
    (label = "R23", points = "183,190 192,228 194,229 224,216 226,191 197,178"),
    (
        label = "R24",
        points = "239,182 226,191 224,216 249,235 256,225 262,215 268,203 271,192",
    ),
    (label = "R25", points = "158,187 145,203 165,237 192,228 183,190"),
    (label = "R26", points = "97,235 117,234 129,206 109,188 81,209"),
    (label = "R27", points = "129,206 117,234 130,250 161,243 165,237 145,203"),
    (label = "R28", points = "97,235 81,209 74,207 45,227 52,237 60,246 69,254 79,261"),
    (label = "R29", points = "224,216 194,229 212,267 222,261 232,253 241,245 249,235"),
    (label = "R30", points = "194,229 192,228 165,237 161,243 172,281 193,276 212,267"),
    (
        label = "R31",
        points = "130,250 117,234 97,235 79,261 89,268 100,273 111,277 122,280",
    ),
    (label = "R32", points = "161,243 130,250 122,280 135,282 148,283 160,283 172,281"),
]

const TOPO_REGIONS = TOPO_REGIONS_32

Base.@kwdef struct RegionHeadDomain
    xg::Vector{Float32}
    yg::Vector{Float32}
    mask::BitMatrix
    center::Point2f
    radius::Float32
    boundary_polygon::Vector{Point2f}
end

# Remove duplicate vertices and collinear points from a polygon loop.
function _clean_region_polygon(poly; atol = 1.0f-5)
    isempty(poly) && return Point2f[]

    pts = Point2f[]
    for p in poly
        q = Point2f(Float32(p[1]), Float32(p[2]))
        if isempty(pts) || hypot(q[1] - pts[end][1], q[2] - pts[end][2]) > atol
            push!(pts, q)
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
            abx = Float64(b[1] - a[1])
            aby = Float64(b[2] - a[2])
            bcx = Float64(c[1] - b[1])
            bcy = Float64(c[2] - b[2])
            cross = abs(abx * bcy - aby * bcx)
            if cross <= atol
                keep[i] = false
                changed = true
            end
        end
        pts = pts[keep]
    end

    pts
end

# Build a fallback circular boundary polygon from a center and radius.
function _boundary_polygon_from_circle(center::Point2f, radius::Float32)
    circle = GeometryBasics.Circle(Point2f(center[1], center[2]), radius)
    _clean_region_polygon(Point2f.(GeometryBasics.decompose(Point2f, circle)))
end

# Extract a boundary polygon from a rendered geometry object when possible.
function _geometry_boundary_polygon(geometry)
    isnothing(geometry) && return nothing
    try
        return _clean_region_polygon(Point2f.(GeometryBasics.decompose(Point2f, geometry)))
    catch
        return nothing
    end
end

# Read center and radius from rendered geometry, with grid-based fallbacks.
function _geometry_center_radius(geometry, fallback_center::Point2f, fallback_radius::Float32)
    isnothing(geometry) && return fallback_center, fallback_radius

    center = try
        o = GeometryBasics.origin(geometry)
        Point2f(Float32(o[1]), Float32(o[2]))
    catch
        fallback_center
    end

    radius = try
        Float32(GeometryBasics.radius(geometry))
    catch
        fallback_radius
    end

    center, radius
end

# Infer a circular sampling mask from the grid extents.
function _default_topoplot_mask(xs, ys, center::Point2f, radius)
    dx = length(xs) > 1 ? abs(Float32(xs[2] - xs[1])) : 0f0
    dy = length(ys) > 1 ? abs(Float32(ys[2] - ys[1])) : 0f0
    tol = max(dx, dy)
    BitMatrix([
        hypot(Float32(x) - center[1], Float32(y) - center[2]) <= radius + tol for x in xs,
        y in ys
    ])
end

"""
    region_head_domain(xs, ys; mask=nothing, geometry=nothing)

Build the canonical target head domain from a rendered topoplot grid.

If `mask` is not provided, a circular mask is inferred from the grid extents.
"""
# Build the canonical head domain from a topoplot grid and optional geometry.
function region_head_domain(xs, ys; mask = nothing, geometry = nothing)
    xg = Float32.(collect(xs))
    yg = Float32.(collect(ys))
    fallback_center = Point2f(
        Float32((first(xg) + last(xg)) / 2),
        Float32((first(yg) + last(yg)) / 2),
    )
    fallback_radius = Float32((last(xg) - first(xg)) / 2)
    center, radius = _geometry_center_radius(geometry, fallback_center, fallback_radius)
    boundary_polygon = something(
        _geometry_boundary_polygon(geometry),
        _boundary_polygon_from_circle(center, radius),
    )
    resolved_mask = isnothing(mask) ? _default_topoplot_mask(xg, yg, center, radius) : BitMatrix(mask)
    RegionHeadDomain(; xg, yg, mask = resolved_mask, center, radius, boundary_polygon)
end

"""
    region_head_domain_from_plot(h)

Derive the canonical target head domain from a rendered `eeg_topoplot!` object.
"""
# Pull the canonical head domain directly from a rendered topoplot object.
function region_head_domain_from_plot(h)
    tp = h.plots[1]
    region_head_domain(tp.xg[], tp.yg[]; mask = tp.mask[], geometry = tp.geometry[])
end

"""
    topoplot_head_limits(center, radius; pad_fraction=0.025f0)
    topoplot_head_limits(domain::RegionHeadDomain; pad_fraction=0.025f0)

Return axis limits that keep the head circle, ears, and nose visible with a small pad.
"""
# Compute padded axis limits that keep the full head outline visible.
function topoplot_head_limits(center, radius; pad_fraction = 0.025f0)
    cx = Float32(center[1])
    cy = Float32(center[2])
    radius = Float32(radius)
    diameter = 2radius
    outline_pts = Point2f[
        Point2f(cx - 1.10f0 * radius, cy),
        Point2f(cx + 1.10f0 * radius, cy),
        Point2f(cx, cy - radius),
        Point2f(cx, cy + 1.12f0 * radius),
        Point2f(cx - 0.14f0 * diameter, cy + 0.98f0 * radius),
        Point2f(cx + 0.14f0 * diameter, cy + 0.98f0 * radius),
    ]
    xmin = minimum(p[1] for p in outline_pts)
    xmax = maximum(p[1] for p in outline_pts)
    ymin = minimum(p[2] for p in outline_pts)
    ymax = maximum(p[2] for p in outline_pts)
    xpad = (xmax - xmin) * pad_fraction
    ypad = (ymax - ymin) * pad_fraction
    (xmin - xpad, xmax + xpad, ymin - ypad, ymax + ypad)
end

# Delegate head-limit calculation to the stored domain geometry.
topoplot_head_limits(domain::RegionHeadDomain; pad_fraction = 0.025f0) =
    topoplot_head_limits(domain.center, domain.radius; pad_fraction = pad_fraction)

"""
    map_template_to_head(x, y; template_center=(150.0f0, 150.0f0), template_radius=150.0f0,
                         head_center=(0f0, -0.08f0), head_radius=1.33f0)

Convert x,y coordinates from the template image to topoplot head coordinates.

# Return Value
`Point{2, Float32}` with the converted coordinates in head space.
"""
# Map a template-space coordinate pair into head-space coordinates.
function map_template_to_head(
    x,
    y;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
)
    tx = (x - template_center[1]) / template_radius
    ty = -(y - template_center[2]) / template_radius
    return Point2f(head_center[1] + head_radius * tx, head_center[2] + head_radius * ty)
end

# Forward point-based template mapping to the scalar coordinate method.
map_template_to_head(p::Point2f; kwargs...) = map_template_to_head(p[1], p[2]; kwargs...)

"""
    parse_region_polygon(s; kwargs...)

Parse a region polygon from a string of x,y point pairs and convert it to head coordinates.

# Return Value
`Vector{Point{2, Float32}}` containing the polygon vertices in head coordinates.
"""
# Parse a template-space polygon string into head-space points.
function parse_region_polygon(s::AbstractString; kwargs...)
    pts = Point2f[]
    for pair in split(strip(s))
        x, y = split(pair, ",")
        push!(pts, map_template_to_head(parse(Float32, x), parse(Float32, y); kwargs...))
    end
    return pts
end

"""
    region_polygon(region; kwargs...)

Convert the polygon points stored in `region.points` to head coordinates.

# Return Value
`Vector{Point{2, Float32}}` containing the polygon vertices in head coordinates.
"""
# Parse the polygon stored on a region record.
region_polygon(region; kwargs...) = parse_region_polygon(region.points; kwargs...)

# Parse every authored region polygon into source head space.
function _source_region_polygons(
    regions;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
)
    [
        region_polygon(
            reg;
            template_center = template_center,
            template_radius = template_radius,
            head_center = head_center,
            head_radius = head_radius,
        ) for reg in regions
    ]
end

# Quantize a point so shared edges can be matched robustly.
_point_key(p::Point2f; scale = 1.0f6) = (
    round(Int, Float64(p[1]) * scale),
    round(Int, Float64(p[2]) * scale),
)

# Build an order-independent key for a polygon edge.
function _edge_key(p::Point2f, q::Point2f; scale = 1.0f6)
    pk = _point_key(p; scale = scale)
    qk = _point_key(q; scale = scale)
    pk <= qk ? (pk, qk) : (qk, pk)
end

# Compute the 2D scalar cross product of two vectors.
_cross2(ax, ay, bx, by) = ax * by - ay * bx

# Count how often each edge appears across a polygon collection.
function _polygon_edge_inventory(polys)
    counts = Dict{Tuple{Tuple{Int,Int},Tuple{Int,Int}},Int}()
    segments = Dict{Tuple{Tuple{Int,Int},Tuple{Int,Int}},Tuple{Point2f,Point2f}}()

    for poly in polys
        n = length(poly)
        n < 2 && continue
        for i in 1:n
            p = poly[i]
            q = poly[i == n ? 1 : i + 1]
            key = _edge_key(p, q)
            counts[key] = get(counts, key, 0) + 1
            segments[key] = (p, q)
        end
    end

    counts, segments
end

# Collect the edges that belong to the outer boundary of the partition.
function _boundary_edges(polys)
    counts, segments = _polygon_edge_inventory(polys)
    keys = Set(key for (key, count) in counts if count == 1)
    edges = [segments[key] for key in keys]
    (; keys, edges)
end

# Expand a polygon into its directed edge list.
function _polygon_edges(poly)
    n = length(poly)
    n < 2 && return Tuple{Point2f,Point2f}[]
    [(poly[i], poly[i == n ? 1 : i + 1]) for i in 1:n]
end

# Intersect a ray from the center with one line segment.
function _ray_segment_intersection(center::Point2f, p::Point2f, q::Point2f, θ; atol = 1.0e-7)
    dirx = cos(θ)
    diry = sin(θ)
    vx = Float64(q[1] - p[1])
    vy = Float64(q[2] - p[2])
    wx = Float64(p[1] - center[1])
    wy = Float64(p[2] - center[2])
    den = _cross2(vx, vy, dirx, diry)
    abs(den) <= atol && return nothing

    t = -_cross2(wx, wy, dirx, diry) / den
    (-atol <= t <= 1 + atol) || return nothing

    ix = Float64(p[1]) + t * vx
    iy = Float64(p[2]) + t * vy
    u = (ix - Float64(center[1])) * dirx + (iy - Float64(center[2])) * diry
    u >= -atol || return nothing

    (; t = clamp(t, 0.0, 1.0), radius = max(0.0, u))
end

# Find the farthest boundary hit along a ray at the given angle.
function _boundary_radius_at_angle(center::Point2f, edges, θ; fallback = nothing, atol = 1.0e-7)
    radii = Float64[]
    for (p, q) in edges
        hit = _ray_segment_intersection(center, p, q, θ; atol = atol)
        isnothing(hit) || push!(radii, hit.radius)
    end

    if isempty(radii)
        isnothing(fallback) && error("No boundary intersection found for angle $θ.")
        return Float64(fallback)
    end

    maximum(radii)
end

# Split an edge into stable sample positions before boundary-aware remapping.
function _segment_split_parameters(
    p::Point2f,
    q::Point2f;
    center::Point2f,
    max_step,
    split_angles = Float64[],
    include_boundary_vertices = false,
    atol = 1.0e-7,
)
    seglen = hypot(q[1] - p[1], q[2] - p[2])
    n_uniform = max(1, ceil(Int, seglen / max(Float32(max_step), 1.0f-4)))
    ts = Float64[k / n_uniform for k in 0:(n_uniform-1)]

    if include_boundary_vertices
        for θ in split_angles
            hit = _ray_segment_intersection(center, p, q, θ; atol = atol)
            if !isnothing(hit) && atol < hit.t < 1 - atol
                push!(ts, hit.t)
            end
        end
    end

    sort!(ts)
    unique_ts = Float64[]
    for t in ts
        t_clamped = clamp(t, 0.0, 1.0)
        if isempty(unique_ts) || abs(t_clamped - unique_ts[end]) > 1.0e-6
            push!(unique_ts, t_clamped)
        end
    end

    unique_ts
end

# Map one source-space point onto the target boundary using radial fractions.
function _map_point_between_boundaries(
    p::Point2f,
    source_center::Point2f,
    source_edges,
    target_center::Point2f,
    target_edges;
    source_fallback_radius,
    target_fallback_radius,
)
    vx = Float64(p[1] - source_center[1])
    vy = Float64(p[2] - source_center[2])
    r = hypot(vx, vy)
    r <= 1.0e-10 && return Point2f(target_center[1], target_center[2])

    θ = atan(vy, vx)
    source_limit = _boundary_radius_at_angle(
        source_center,
        source_edges,
        θ;
        fallback = source_fallback_radius,
    )
    target_limit = _boundary_radius_at_angle(
        target_center,
        target_edges,
        θ;
        fallback = target_fallback_radius,
    )
    source_limit > 0 || return Point2f(target_center[1], target_center[2])

    ρ = clamp(r / source_limit, 0.0, 1.0)
    mapped_r = ρ * target_limit
    Point2f(
        Float32(target_center[1] + mapped_r * cos(θ)),
        Float32(target_center[2] + mapped_r * sin(θ)),
    )
end

"""
    fit_region_polygons_to_domain(regions, domain; template_center, template_radius, head_center, head_radius)

Parse a region set in its authored source geometry and map it onto a canonical topoplot head domain.
The authored `head_center` defines alignment; the effective source scale is taken from the polygons'
outer extent around that center.
"""
# Remap authored region polygons onto the canonical rendered head domain.
function fit_region_polygons_to_domain(
    regions,
    domain::RegionHeadDomain;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
)
    source_polys = _source_region_polygons(
        regions;
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
    )
    source_center = Point2f(Float32(head_center[1]), Float32(head_center[2]))
    pts = isempty(source_polys) ? Point2f[] : reduce(vcat, source_polys)
    source_radius = isempty(pts) ? 0f0 :
        maximum(hypot(p[1] - source_center[1], p[2] - source_center[2]) for p in pts)
    source_radius > 0f0 || error("Region set has zero effective radius and cannot be mapped to a topoplot domain.")

    source_boundary = _boundary_edges(source_polys)
    source_boundary_edges = source_boundary.edges
    target_boundary_edges = _polygon_edges(domain.boundary_polygon)
    target_vertex_angles = Float64[
        atan(Float64(p[2] - domain.center[2]), Float64(p[1] - domain.center[1])) for
        p in domain.boundary_polygon
    ]
    sample_step = max(source_radius / max(length(domain.boundary_polygon) / 2, 16), 0.02f0)

    fitted_polygons = Vector{Point2f}[]
    for poly in source_polys
        mapped = Point2f[]
        n = length(poly)
        for i in 1:n
            p = poly[i]
            q = poly[i == n ? 1 : i + 1]
            edge_key = _edge_key(p, q)
            is_boundary_edge = edge_key in source_boundary.keys
            ts = _segment_split_parameters(
                p,
                q;
                center = source_center,
                max_step = sample_step,
                split_angles = target_vertex_angles,
                include_boundary_vertices = is_boundary_edge,
            )

            for t in ts
                sample = Point2f(
                    Float32(p[1] + t * (q[1] - p[1])),
                    Float32(p[2] + t * (q[2] - p[2])),
                )
                push!(
                    mapped,
                    _map_point_between_boundaries(
                        sample,
                        source_center,
                        source_boundary_edges,
                        domain.center,
                        target_boundary_edges;
                        source_fallback_radius = source_radius,
                        target_fallback_radius = domain.radius,
                    ),
                )
            end
        end
        push!(fitted_polygons, _clean_region_polygon(mapped))
    end

    (; domain, source_center, source_radius, polygons = fitted_polygons)
end

# Remap a single region polygon onto the canonical rendered head domain.
function fit_region_polygon_to_domain(region, domain::RegionHeadDomain; kwargs...)
    fit_region_polygons_to_domain((region,), domain; kwargs...).polygons[1]
end

"""
    polygon_centroid(poly)

Compute a center point for placing a label inside a polygon.

# Return Value
`Point{2, Float32}` giving the label position.
"""
# Estimate a simple centroid for label placement inside a polygon.
function polygon_centroid(poly::AbstractVector{<:Point2})
    xs = Float32[p[1] for p in poly]
    ys = Float32[p[2] for p in poly]
    return Point2f(mean(xs), mean(ys))
end

# Bilinearly sample the head mask at an arbitrary continuous position.
function topoplot_mask_value(x, y, domain::RegionHeadDomain)
    x < first(domain.xg) && return 0f0
    x > last(domain.xg) && return 0f0
    y < first(domain.yg) && return 0f0
    y > last(domain.yg) && return 0f0

    length(domain.xg) == 1 && return domain.mask[1, 1] ? 1f0 : 0f0
    length(domain.yg) == 1 && return domain.mask[1, 1] ? 1f0 : 0f0

    dx = domain.xg[2] - domain.xg[1]
    dy = domain.yg[2] - domain.yg[1]
    fx = clamp((x - domain.xg[1]) / dx + 1, 1, length(domain.xg) - 1)
    fy = clamp((y - domain.yg[1]) / dy + 1, 1, length(domain.yg) - 1)
    i = clamp(floor(Int, fx), 1, length(domain.xg) - 1)
    j = clamp(floor(Int, fy), 1, length(domain.yg) - 1)
    tx = fx - i
    ty = fy - j

    m11 = domain.mask[i, j] ? 1f0 : 0f0
    m21 = domain.mask[i + 1, j] ? 1f0 : 0f0
    m12 = domain.mask[i, j + 1] ? 1f0 : 0f0
    m22 = domain.mask[i + 1, j + 1] ? 1f0 : 0f0

    (1 - tx) * (1 - ty) * m11 + tx * (1 - ty) * m21 + (1 - tx) * ty * m12 + tx * ty * m22
end

# Test whether a point lies inside the sampled topoplot domain mask.
point_in_topoplot_domain(x, y, domain::RegionHeadDomain; threshold = 0.5f0) =
    topoplot_mask_value(x, y, domain) >= threshold

"""
    overlay_region_polygons!(ax, regions; kwargs...)

Draw region polygon borders and labels on an existing axis.
# Arguments
- `ax`: Axis to draw on.
- `regions`: Collection of regions with polygon point strings and labels.

# Keyword Arguments
- `head_center`: Center of the head in plot coordinates.
- `head_radius`: Radius of the head in plot coordinates.
- `template_center`: Center of the template (source) image coordinate system.
- `template_radius`: Radius of the template image coordinate system.
- `topoplot_domain`: Canonical target head domain to fit the regions onto.
- `topoplot_plot`: Rendered `eeg_topoplot!` object used to derive the canonical target domain.
- `topoplot_labels`: Labels used to render a transparent topoplot when only labels are available.
- `topoplot_positions`: Explicit positions used with `topoplot_labels` or by themselves.
- `fontsize`: Font size for region labels.
- `linewidth`: Line width for polygon borders.

# Return Value
The updated `Axis` with the region polygons and labels overlaid.
"""
# Draw region outlines and labels using either source space or a fitted head domain.
function overlay_region_polygons!(
    ax::Axis,
    regions;
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    template_center = (150.0, 150.0),
    template_radius = 150.0,
    topoplot_domain = nothing,
    topoplot_plot = nothing,
    topoplot_labels = nothing,
    topoplot_positions = nothing,
    fontsize = 20,
    linewidth = 2,
    fontcolor = :black,
)
    domain = isnothing(topoplot_domain) ? (
        isnothing(topoplot_plot) ? nothing : region_head_domain_from_plot(topoplot_plot)
    ) : topoplot_domain

    if isnothing(domain) && (!isnothing(topoplot_labels) || !isnothing(topoplot_positions))
        positions = isnothing(topoplot_positions) ?
            TopoPlots.labels2positions(topoplot_labels) : topoplot_positions
        dummy = collect(LinRange(0f0, 1f0, length(positions)))
        transparent_cmap = cgrad([RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0)])
        transparent_plot = eeg_topoplot!(
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
        domain = region_head_domain_from_plot(transparent_plot)
    end

    polys = isnothing(domain) ? _source_region_polygons(
        regions;
        head_center = head_center,
        head_radius = head_radius,
        template_center = template_center,
        template_radius = template_radius,
    ) : fit_region_polygons_to_domain(
        regions,
        domain;
        head_center = head_center,
        head_radius = head_radius,
        template_center = template_center,
        template_radius = template_radius,
    ).polygons

    !isnothing(domain) && limits!(ax, topoplot_head_limits(domain)...)

    for (reg, poly) in zip(regions, polys)

        lines!(
            ax,
            [p[1] for p in poly] |> x -> vcat(x, first(x)),
            [p[2] for p in poly] |> y -> vcat(y, first(y));
            color = :black,
            linewidth = linewidth,
        )

        c = polygon_centroid(poly)
        text!(
            ax, c[1], c[2];
            text = reg.label,
            align = (:center, :center),
            fontsize = fontsize,
            color = fontcolor,
        )
    end

    return ax
end

"""
    point_in_polygon(x, y, poly)

Check whether a point lies inside a polygon.

# Return Value
`Bool` indicating whether the point `(x, y)` is inside the polygon.
"""
# Evaluate point-in-polygon membership with a ray-casting test.
function point_in_polygon(x, y, poly)
    inside = false
    n = length(poly)
    j = n
    for i = 1:n
        xi, yi = poly[i][1], poly[i][2]
        xj, yj = poly[j][1], poly[j][2]

        hit =
            ((yi > y) != (yj > y)) &&
            (x < (xj - xi) * (y - yi) / ((yj - yi) + 1.0f-12) + xi)

        if hit
            inside = !inside
        end
        j = i
    end
    return inside
end

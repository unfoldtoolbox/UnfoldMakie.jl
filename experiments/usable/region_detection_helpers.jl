const TOPO_REGIONS = [
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
    (label = "R24", points = "239,182 226,191 224,216 249,235 256,225 262,215 268,203 271,192"),
    (label = "R25", points = "158,187 145,203 165,237 192,228 183,190"),
    (label = "R26", points = "97,235 117,234 129,206 109,188 81,209"),
    (label = "R27", points = "129,206 117,234 130,250 161,243 165,237 145,203"),
    (label = "R28", points = "97,235 81,209 74,207 45,227 52,237 60,246 69,254 79,261"),
    (label = "R29", points = "224,216 194,229 212,267 222,261 232,253 241,245 249,235"),
    (label = "R30", points = "194,229 192,228 165,237 161,243 172,281 193,276 212,267"),
    (label = "R31", points = "130,250 117,234 97,235 79,261 89,268 100,273 111,277 122,280"),
    (label = "R32", points = "161,243 130,250 122,280 135,282 148,283 160,283 172,281"),
]


"""
    map_template_to_head(x, y; template_center=(150.0f0, 150.0f0), template_radius=150.0f0,
                         head_center=(0f0, -0.08f0), head_radius=1.33f0)

Convert x,y coordinates from the template image to topoplot head coordinates.

# Return Value
`Point{2, Float32}` with the converted coordinates in head space.
"""
function map_template_to_head(x, y;
    template_center=(150.0f0, 150.0f0),
    template_radius=150.0f0,
    head_center=(0f0, -0.08f0),
    head_radius=1.33f0,
)
    tx = (x - template_center[1]) / template_radius
    ty = -(y - template_center[2]) / template_radius
    return Point2f(
        head_center[1] + head_radius * tx,
        head_center[2] + head_radius * ty,
    )
end

map_template_to_head(p::Point2f; kwargs...) =
    map_template_to_head(p[1], p[2]; kwargs...)

"""
    parse_region_polygon(s; kwargs...)

Parse a region polygon from a string of x,y point pairs and convert it to head coordinates.

# Return Value
`Vector{Point{2, Float32}}` containing the polygon vertices in head coordinates.
"""
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
region_polygon(region; kwargs...) = parse_region_polygon(region.points; kwargs...)



"""
    polygon_centroid(poly)

Compute a center point for placing a label inside a polygon.

# Return Value
`Point{2, Float32}` giving the label position.
"""
function polygon_centroid(poly::AbstractVector{<:Point2})
    xs = Float32[p[1] for p in poly]
    ys = Float32[p[2] for p in poly]
    return Point2f(mean(xs), mean(ys))
end

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
- `fontsize`: Font size for region labels.
- `linewidth`: Line width for polygon borders.

# Return Value
The updated `Axis` with the region polygons and labels overlaid.
"""
function overlay_region_polygons!(
    ax::Axis,
    regions;
    head_center=(0f0, -0.12f0),
    head_radius=1.12f0,
    template_center=(150.0, 150.0),
    template_radius=150.0,
    fontsize=20,
    linewidth=2,
)
    for reg in regions
        poly = parse_region_polygon(
            reg.points;
            head_center=head_center,
            head_radius=head_radius,
            template_center=template_center,
            template_radius=template_radius,
        )

        lines!(
            ax,
            [p[1] for p in poly] |> x -> vcat(x, first(x)),
            [p[2] for p in poly] |> y -> vcat(y, first(y));
            color=:black,
            linewidth=linewidth,
        )

        c = polygon_centroid(poly)
        text!(ax, c[1], c[2]; text=reg.label, align=(:center, :center),
              fontsize=fontsize, color=:black)
    end

    return ax
end




# ---------- geometry ----------
"""
    point_in_polygon(x, y, poly)

Check whether a point lies inside a polygon.

# Return Value
`Bool` indicating whether the point `(x, y)` is inside the polygon.
"""
function point_in_polygon(x, y, poly)
    inside = false
    n = length(poly)
    j = n
    for i in 1:n
        xi, yi = poly[i][1], poly[i][2]
        xj, yj = poly[j][1], poly[j][2]

        hit = ((yi > y) != (yj > y)) &&
              (x < (xj - xi) * (y - yi) / ((yj - yi) + 1f-12) + xi)

        if hit
            inside = !inside
        end
        j = i
    end
    return inside
end

# ---------- interpolation ----------
"""
    idw_value(x, y, positions, values; power=2.0f0, eps=1f-6)

Interpolate a value at point `(x, y)` from nearby sample positions using inverse-distance weighting. So nearer points contribute more than farther ones.

**Return Value**: `Float32`.
"""
function idw_value(x, y, positions, values; power=2.0f0, eps=1f-6)
    num = 0.0f0 # numerator
    den = 0.0f0 # denominator
    for (p, v) in zip(positions, values)
        dx = x - p[1]
        dy = y - p[2]
        d2 = dx*dx + dy*dy

        if d2 < eps
            return Float32(v)
        end

        w = 1f0 / (sqrt(d2)^power)
        num += w * Float32(v)
        den += w
    end
   
    return num / den
end

# ---------- region scoring ----------
"""
    region_score(
        region, positions, values;
        template_center=(150.0f0, 150.0f0),
        template_radius=150.0f0,
        head_center=(0f0, -0.08f0),
        head_radius=1.33f0,
        samples=45,
        agg=:mean,
    )

Compute a score for one region from interpolated values sampled inside its polygon.

# Arguments
- `region`: Region definition containing polygon points.
- `positions`: Electrode positions used for interpolation.
- `values`: Values at the electrode positions.

# Keyword Arguments
- `template_center`: Center of the template image coordinate system.
- `template_radius`: Radius of the template image coordinate system.
- `head_center`: Center of the head in plot coordinates.
- `head_radius`: Radius of the head in plot coordinates.
- `samples`: Number of grid samples per axis inside the region bounding box.
- `agg`: Aggregation method for sampled values (`:mean`, `:max`, or `:median`).

# Return Value
A region score as a floating-point value, or `NaN32` if no sample points fall inside the polygon.
"""
function region_score(region, positions, values;
    template_center=(150.0f0, 150.0f0),
    template_radius=150.0f0,
    head_center=(0f0, -0.08f0),
    head_radius=1.33f0,
    samples=45,
    agg=:mean,
)
    poly = region_polygon(
        region;
        template_center=template_center,
        template_radius=template_radius,
        head_center=head_center,
        head_radius=head_radius,
    )

    xs = [p[1] for p in poly]
    ys = [p[2] for p in poly]

    xmin, xmax = minimum(xs), maximum(xs)
    ymin, ymax = minimum(ys), maximum(ys)

    vals = Float32[]
    gx = range(xmin, xmax; length=samples)
    gy = range(ymin, ymax; length=samples)

    for x in gx, y in gy
        if point_in_polygon(x, y, poly)
            push!(vals, idw_value(x, y, positions, values))
        end
    end

    isempty(vals) && return NaN32

    if agg == :mean
        return mean(vals)
    elseif agg == :max
        return maximum(vals)
    elseif agg == :median
        return median(vals)
    else
        error("Unknown agg = $agg")
    end
end

function rank_regions(positions, values, regions;
    template_center=(150.0f0, 150.0f0),
    template_radius=150.0f0,
    head_center=(0f0, -0.08f0),
    head_radius=1.33f0,
    samples=45,
    agg=:mean,
)
    scores = [
        (
            label = reg.label,
            score = region_score(
                reg, positions, values;
                template_center=template_center,
                template_radius=template_radius,
                head_center=head_center,
                head_radius=head_radius,
                samples=samples,
                agg=agg,
            ),
        )
        for reg in regions
    ]

    sort(scores; by = x -> x.score, rev = true)
end


"""
    region_weights(positions, values, regions;
        agg=:mean,
        samples=45,
        template_center=(150.0f0, 150.0f0),
        template_radius=150.0f0,
        head_center=(0f0, -0.08f0),
        head_radius=1.33f0,
        binning=:equal_width,
        n_bins=4,
        reverse=false,
    )

Compute one raw score per region from the interpolated field inside each polygon,
then convert those raw scores to integer weights 1:n_bins.

Returns a vector of named tuples:
(label, raw_score, weight)
"""
function region_weights(positions, values, regions;
    agg=:mean,
    samples=45,
    template_center=(150.0f0, 150.0f0),
    template_radius=150.0f0,
    head_center=(0f0, -0.08f0),
    head_radius=1.33f0,
    binning=:equal_width,
    n_bins=4,
    reverse=false,
)
    rows = [
        (
            label = reg.label,
            raw_score = region_score(
                reg, positions, values;
                template_center=template_center,
                template_radius=template_radius,
                head_center=head_center,
                head_radius=head_radius,
                samples=samples,
                agg=agg,
            )
        )
        for reg in regions
    ]

    raw = Float64[r.raw_score for r in rows]
    valid = filter(!isnan, raw)

    isempty(valid) && error("No valid region scores.")

    lo, hi = minimum(valid), maximum(valid)

    weights = if binning == :equal_width
        if hi == lo
            fill(n_bins, length(raw))
        else
            [
                isnan(x) ? 0 :
                clamp(floor(Int, (x - lo) / (hi - lo) * n_bins) + 1, 1, n_bins)
                for x in raw
            ]
        end

    elseif binning == :quantile
        qs = [quantile(valid, k / n_bins) for k in 1:(n_bins - 1)]
        [
            isnan(x) ? 0 :
            1 + count(q -> x > q, qs)
            for x in raw
        ]

    else
        error("binning must be :equal_width or :quantile")
    end

    if reverse
        weights = [w == 0 ? 0 : (n_bins + 1 - w) for w in weights]
    end

    out = [
        (label = rows[i].label, raw_score = rows[i].raw_score, weight = weights[i])
        for i in eachindex(rows)
    ]

    sort(out; by = x -> x.raw_score, rev = true)
end

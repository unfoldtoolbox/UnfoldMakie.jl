# ---------- interpolation ----------
"""
    idw_value(x, y, positions, values; power=2.0f0, eps=1f-6)

Interpolate a value at point `(x, y)` from nearby sample positions using inverse-distance weighting. So nearer points contribute more than farther ones.

**Return Value**: `Float32`.
"""
function idw_value(x, y, positions, values; power = 2.0f0, eps = 1.0f-6)
    num = 0.0f0 # numerator
    den = 0.0f0 # denominator
    for (p, v) in zip(positions, values)
        dx = x - p[1]
        dy = y - p[2]
        d2 = dx * dx + dy * dy

        if d2 < eps
            return Float32(v)
        end

        w = 1.0f0 / (sqrt(d2)^power)
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
function region_score(
    region,
    positions,
    values;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    topoplot_domain = nothing,
    samples = 45,
    agg = :mean,
)
    poly = isnothing(topoplot_domain) ? region_polygon(
        region;
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
    ) : fit_region_polygon_to_domain(
        region,
        topoplot_domain;
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
    )

    xs = [p[1] for p in poly]
    ys = [p[2] for p in poly]

    xmin, xmax = minimum(xs), maximum(xs)
    ymin, ymax = minimum(ys), maximum(ys)

    vals = Float32[]
    gx = range(xmin, xmax; length = samples)
    gy = range(ymin, ymax; length = samples)

    for x in gx, y in gy
        if point_in_polygon(x, y, poly) &&
           (isnothing(topoplot_domain) || point_in_topoplot_domain(x, y, topoplot_domain))
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
    elseif agg == :signed_peak
        return vals[argmax(abs.(vals))]
    elseif agg == :q90
        return quantile(vals, 0.90)
    elseif agg == :q95
        return quantile(vals, 0.95)
        error("Unknown agg = $agg")
    end
end

function rank_regions(
    positions,
    values,
    regions;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    topoplot_domain = nothing,
    samples = 45,
    agg = :mean,
)
    scores = [
        (
            label = reg.label,
            score = region_score(
                reg,
                positions,
                values;
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                topoplot_domain = topoplot_domain,
                samples = samples,
                agg = agg,
            ),
        ) for reg in regions
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
        reverse=true,
    )

Compute one raw score per region from the interpolated field inside each polygon,
then convert those raw scores to integer weights 1:n_bins.

Returns a vector of named tuples:
(label, raw_score, weight)
"""
function region_weights(
    positions,
    values,
    regions;
    agg = :mean,
    samples = 45,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    topoplot_domain = nothing,
    binning = :equal_width,
    n_bins = 4,
    reverse = true,
)
    rows = [
        (
            label = reg.label,
            raw_score = region_score(
                reg,
                positions,
                values;
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                topoplot_domain = topoplot_domain,
                samples = samples,
                agg = agg,
            ),
        ) for reg in regions
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
                clamp(floor(Int, (x - lo) / (hi - lo) * n_bins) + 1, 1, n_bins) for
                x in raw
            ]
        end

    elseif binning == :quantile
        qs = [quantile(valid, k / n_bins) for k = 1:(n_bins-1)]
        [isnan(x) ? 0 : 1 + count(q -> x > q, qs) for x in raw]

    else
        error("binning must be :equal_width or :quantile")
    end

    if reverse
        weights = [w == 0 ? 0 : (n_bins + 1 - w) for w in weights]
    end

    out = [
        (label = rows[i].label, raw_score = rows[i].raw_score, weight = weights[i]) for
        i in eachindex(rows)
    ]

    sort(out; by = x -> x.raw_score, rev = true)
end

# not used
#=
function signed_region_weights(
    positions,
    values,
    regions;
    agg = :mean,
    samples = 45,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    binning = :equal_width,
    n_bins = 4,
    zero_side = :positive,
)
    iseven(n_bins) || error("signed_region_weights requires an even n_bins, e.g. 4")
    half = n_bins ÷ 2

    rows = [
        (
            label = reg.label,
            raw_score = region_score(
                reg,
                positions,
                values;
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                samples = samples,
                agg = agg,
            ),
        ) for reg in regions
    ]

    raw = Float64[r.raw_score for r in rows]
    valid = filter(!isnan, raw)
    isempty(valid) && error("No valid region scores.")

    absvalid = abs.(valid)

    magbin = if binning == :equal_width
        hi = maximum(absvalid)

        if hi == 0
            x -> 1
        else
            x -> clamp(floor(Int, abs(x) / hi * half) + 1, 1, half)
        end

    elseif binning == :quantile
        qs = [quantile(absvalid, k / half) for k = 1:(half-1)]
        x -> 1 + count(q -> abs(x) > q, qs)

    else
        error("binning must be :equal_width or :quantile")
    end

    function signed_bin(x)
        isnan(x) && return 0

        mag = magbin(x)

        if x < 0
            return half + 1 - mag
        elseif x > 0
            return half + mag
        else
            return zero_side == :positive ? (half + 1) : half
        end
    end

    out = [
        (
            label = rows[i].label,
            raw_score = rows[i].raw_score,
            weight = signed_bin(rows[i].raw_score),
        ) for i in eachindex(rows)
    ]

    sort(out; by = x -> x.raw_score, rev = true)
end
=#

function _region_score_from_grid_poly(
    poly,
    domain,
    xs,
    ys,
    Z;
    agg = :mean,
)
    vals = Float32[]

    for j in eachindex(ys), i in eachindex(xs)
        domain.mask[i, j] || continue
        x = xs[i]
        y = ys[j]

        if point_in_polygon(x, y, poly)
            z = Z[i, j]
            if isfinite(z)
                push!(vals, Float32(z))
            end
        end
    end

    isempty(vals) && return NaN32

    if agg == :mean
        return mean(vals)
    elseif agg == :median
        return median(vals)
    elseif agg == :max
        return maximum(vals)
    elseif agg == :q90
        return quantile(vals, 0.90)
    elseif agg == :q95
        return quantile(vals, 0.95)
    else
        error("Unknown agg = $agg")
    end
end

function region_score_from_grid(
    region,
    xs,
    ys,
    Z;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    mask = nothing,
    topoplot_domain = nothing,
    agg = :mean,
)
    domain = isnothing(topoplot_domain) ? region_head_domain(xs, ys; mask = mask) : topoplot_domain
    poly = fit_region_polygon_to_domain(
        region,
        domain;
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
    )
    _region_score_from_grid_poly(poly, domain, xs, ys, Z; agg = agg)
end

function region_weights_from_grid(
    xs,
    ys,
    Z,
    regions;
    agg = :mean,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    mask = nothing,
    topoplot_domain = nothing,
    binning = :quantile,
    n_bins = 4,
    reverse = true,
)
    domain = isnothing(topoplot_domain) ? region_head_domain(xs, ys; mask = mask) : topoplot_domain
    fitted = fit_region_polygons_to_domain(
        regions,
        domain;
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
    )
    rows = [
        (
            label = reg.label,
            raw_score = _region_score_from_grid_poly(
                fitted.polygons[idx],
                domain,
                xs,
                ys,
                Z;
                agg = agg,
            ),
        ) for (idx, reg) in enumerate(regions)
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
                clamp(floor(Int, (x - lo) / (hi - lo) * n_bins) + 1, 1, n_bins) for
                x in raw
            ]
        end
    elseif binning == :quantile
        qs = [quantile(valid, k / n_bins) for k = 1:(n_bins-1)]
        [isnan(x) ? 0 : 1 + count(q -> x > q, qs) for x in raw]
    else
        error("binning must be :equal_width or :quantile")
    end

    if reverse
        weights = [w == 0 ? 0 : (n_bins + 1 - w) for w in weights]
    end

    out = [
        (label = rows[i].label, raw_score = rows[i].raw_score, weight = weights[i]) for
        i in eachindex(rows)
    ]

    sort(out; by = x -> x.raw_score, rev = true)
end

# not used
#=
function signed_region_weights_from_grid(
    xg,
    yg,
    Zmask,
    regions;
    agg = :mean,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    n_bins = 4,
    zero_side = :positive,
    binning = :equal_width,
)
    iseven(n_bins) || error("signed_region_weights_from_grid requires even n_bins")
    half = n_bins ÷ 2

    rows = [
        (
            label = reg.label,
            raw_score = region_score_from_grid(
                reg,
                xg,
                yg,
                Zmask;
                template_center = template_center,
                template_radius = template_radius,
                head_center = head_center,
                head_radius = head_radius,
                agg = agg,
            ),
        ) for reg in regions
    ]

    raw = Float64[r.raw_score for r in rows]
    valid = filter(x -> !isnan(x) && isfinite(x), raw)
    isempty(valid) && error("No valid region scores.")

    absvalid = abs.(valid)

    magbin = if binning == :equal_width
        hi = maximum(absvalid)

        if hi == 0
            x -> 1
        else
            x -> clamp(floor(Int, abs(x) / hi * half) + 1, 1, half)
        end

    elseif binning == :quantile
        qs = [quantile(absvalid, k / half) for k = 1:(half-1)]
        x -> 1 + count(q -> abs(x) > q, qs)

    else
        error("binning must be :equal_width or :quantile")
    end

    function signed_bin(x)
        isnan(x) && return 0
        !isfinite(x) && return 0

        mag = magbin(x)

        if x < 0
            return half + 1 - mag
        elseif x > 0
            return half + mag
        else
            return zero_side == :positive ? (half + 1) : half
        end
    end

    out = [
        (
            label = rows[i].label,
            raw_score = rows[i].raw_score,
            weight = signed_bin(rows[i].raw_score),
        ) for i in eachindex(rows)
    ]

    sort(out; by = x -> x.raw_score, rev = true)
end
=#

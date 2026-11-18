
# -- Optional bivariate contours from image -----------------------------
"""
    draw_bivariate_contours!(
        p, img, x_end, y_end,
        nL, nA, nB, color, linealpha, linewidth,
    )

Draw **perceptual region contours** for a bivariate topoplot by outlining
boundaries between color regions in the rendered image.

This is a thin wrapper around [`bivariate_color_edges_from_img!`] that:
- extracts observable values (`to_value`)
- keeps the calling code in the plotting pipeline clean

The contours are computed by:
1. Converting the rendered RGBA image to CIE L*a*b* space,
2. Quantizing the color space into `(nL × nA × nB)` bins,
3. Detecting label changes between neighboring pixels,
4. Drawing the resulting edges as line segments in plot coordinates.

## Arguments
- `p`\\
    Makie plot, axis, or scene to draw the contour line segments into.
- `img`\\
    Rendered bivariate image (`Matrix{RGBA}` or `Observable` thereof) used to
    compute perceptual color regions.
- `x_end`, `y_end`\\
    Plot extents passed to `image!` (ranges or `ClosedInterval`s), defining the
    coordinate mapping between image pixels and plot space.

## Keyword arguments (kwargs)
- `nL::Int`\\
    Number of bins along the L* (lightness) axis in CIE Lab space.
- `nA::Int`\\
    Number of bins along the a* (green–red) axis in CIE Lab space.
- `nB::Int`\\
    Number of bins along the b* (blue–yellow) axis in CIE Lab space.
- `color`\\
    Line color used to draw the contour edges.
- `linealpha::Real`\\
    Transparency of the contour lines.
- `linewidth::Real`\\
    Width of the contour lines.

### Notes
- The contours reflect **perceptual color regions**, not data-space bins.
- This is intended for visual guidance and segmentation cues, not precise quantitative boundaries.
- Alpha-masked pixels in the image are ignored when computing regions.

"""
function draw_bivariate_contours!(
    p, img, x_end, y_end,
    nL, nA, nB, color, linealpha, linewidth, linestyle,
)
    bivariate_color_edges_from_img!(
        p,
        to_value(img),
        to_value(x_end),
        to_value(y_end);
        nL = nL, nA = nA, nB = nB,
        color = to_value(color),
        linealpha = to_value(linealpha),
        linewidth = to_value(linewidth),
        linestyle = to_value(linestyle),
    )
end

# -- Contours common helper ---------------------------------------------
function draw_scalar_contours_if_any!(p, xg, yg, data)
    contours = to_value(p.contours)
    attributes = @plot_or_defaults contours Attributes(color = (:black, 0.5),
        linestyle = :dot, levels = 6)
    if !isnothing(attributes) && !(p.interpolation[] isa NullInterpolator)
        contour!(p, xg, yg, data; attributes...)
    end
end

function bivar_contours_options(p)
    bivar = get(p.attributes, :bivariate, nothing)
    cont  = (bivar isa Attributes) ? get(bivar, :contours, nothing) : nothing

    cont === nothing && (cont = to_value(_BIVAR_FALLBACK_CONTOURS[]))
    cont === nothing && (cont = Attributes())

    cont isa Attributes || (cont = Attributes(cont))

    bins = to_value(get(cont, :lab_bins, (8, 8, 8)))
    nL, nA, nB = bins

    color     = get(cont, :color, :black)
    linealpha = get(cont, :linealpha, 0.75)
    linewidth = get(cont, :linewidth, 0.9)
    linestyle = get(cont, :linestyle, :dot)
    return (; nL, nA, nB, color, linealpha, linewidth, linestyle)
end


"""
bivariate_color_edges_from_img!(
    p, img, x_end, y_end;
    nL=4, nA=6, nB=6, alpha_cut=0.01,
    color=:black, linealpha=0.75, linewidth=0.9
)

Outline borders between *perceptual color regions* by segmenting the rendered
image `img` in CIE Lab space, then drawing label-change edges.

- img::Matrix{RGBA{Float32}}  (output of your bivariate image!)
- x_end,y_end::same ClosedIntervals (or ranges) you pass to `image!`
- nL,nA,nB :: number of bins along Lab (L*, a*, b*) axes
- alpha_cut :: treat pixels with alpha <= alpha_cut as outside (mask)
"""
function bivariate_color_edges_from_img!(
    p,
    img::AbstractMatrix{<:Colorant},
    x_end, y_end;
    nL::Int = 4, nA::Int = 6, nB::Int = 6,
    alpha_cut::Real = 0.02,
    color = (:black, 0.6),
    linealpha::Real = 0.5,
    linewidth::Real = 0.9,
    linestyle = :dot,
)
    nx, ny = size(img)  # must match how you constructed img (same orientation you used for image!)

    # --- 1) Convert to CIE Lab + build mask from alpha ---
    #The CIE L*a*b* color space (often written simply “Lab”) was designed so that 
    # Euclidean distances correspond roughly to perceived color differences.
    # L* Lightness	0 – 100	how bright/dark the color is (0 = black, 100 = white)
    # a* Green ↔ Red axis	−128 – +128	negative = greenish, positive = reddish
    # b* Blue ↔ Yellow axis	−128 – +128	negative = bluish, positive = yellowish
    L = Array{Float32}(undef, nx, ny)
    A = Array{Float32}(undef, nx, ny)
    B = Array{Float32}(undef, nx, ny)
    mask = falses(nx, ny)

    @inbounds for i in 1:nx, j in 1:ny
        c = img[i, j]
        a = alpha(c)
        if isfinite(a) && a > alpha_cut
            # Convert via RGB -> Lab; RGBA channels are in [0,1]
            lab = convert(Lab, RGB{Float32}(red(c), green(c), blue(c)))
            L[i, j] = Float32(lab.l)   # 0..100 typically
            A[i, j] = Float32(lab.a)   # roughly -128..+128
            B[i, j] = Float32(lab.b)
            mask[i, j] = true
        else
            L[i, j] = NaN32
            A[i, j] = NaN32
            B[i, j] = NaN32
        end
    end

    # --- 2) Compute Lab ranges over valid pixels (robust min/max) ---
    # If needed you can use quantiles; min/max is fine given alpha mask.
    function finite_minmax(X)
        x = vec(X[mask])
        return (minimum(x), maximum(x))
    end
    Lmin, Lmax = finite_minmax(L)
    Amin, Amax = finite_minmax(A)
    Bmin, Bmax = finite_minmax(B)

    # Avoid degenerate ranges
    ϵf = eps(Float32)
    Lrange = max(Lmax - Lmin, ϵf)
    Arange = max(Amax - Amin, ϵf)
    Brange = max(Bmax - Bmin, ϵf)

    # --- 3) Quantize Lab to (nL × nA × nB) region labels ---
    Lbin = fill(NaN32, nx, ny)
    Abin = fill(NaN32, nx, ny)
    Bbin = fill(NaN32, nx, ny)

    @inbounds for i in 1:nx, j in 1:ny
        if mask[i, j]
            lb = clamp(floor((L[i, j] - Lmin) / Lrange * nL) + 1, 1, nL)
            ab = clamp(floor((A[i, j] - Amin) / Arange * nA) + 1, 1, nA)
            bb = clamp(floor((B[i, j] - Bmin) / Brange * nB) + 1, 1, nB)
            Lbin[i, j] = Float32(lb)
            Abin[i, j] = Float32(ab)
            Bbin[i, j] = Float32(bb)
        end
    end

    # Single label index (Float32 with NaNs where masked)
    Label = fill(NaN32, nx, ny)
    @inbounds for i in 1:nx, j in 1:ny
        if mask[i, j]
            # 1..(nL*nA*nB) in row-major style
            Label[i, j] = Lbin[i, j] + (Abin[i, j] - 1f0) * nL + (Bbin[i, j] - 1f0) * (nL * nA)
        end
    end

    # --- 4) Build world-coordinate edges (same geometry as image!) ---
    xa, xb = extrema(x_end)
    ya, yb = extrema(y_end)

    # cell centers
    x_c = collect(LinRange(xa, xb, nx))
    y_c = collect(LinRange(ya, yb, ny))

    # cell edges (midpoints)
    x_e = Vector{Float32}(undef, nx + 1); x_e[1] = xa; x_e[end] = xb
    y_e = Vector{Float32}(undef, ny + 1); y_e[1] = ya; y_e[end] = yb
    @inbounds for i in 1:(nx-1); x_e[i+1] = (x_c[i] + x_c[i+1]) / 2 end
    @inbounds for j in 1:(ny-1); y_e[j+1] = (y_c[j] + y_c[j+1]) / 2 end

    # --- 5) Extract label-change edges as line segments ---
    segs = Point2f[]

    # vertical edges (between (i,j) and (i+1,j))
    @inbounds for i in 1:(nx-1), j in 1:ny
        l1 = Label[i, j]; l2 = Label[i+1, j]
        if isfinite(l1) && isfinite(l2) && l1 != l2
            x = x_e[i+1]
            push!(segs, Point2f(x, y_e[j]), Point2f(x, y_e[j+1]))
        end
    end

    # horizontal edges (between (i,j) and (i,j+1))
    @inbounds for i in 1:nx, j in 1:(ny-1)
        l1 = Label[i, j]; l2 = Label[i, j+1]
        if isfinite(l1) && isfinite(l2) && l1 != l2
            y = y_e[j+1]
            push!(segs, Point2f(x_e[i], y), Point2f(x_e[i+1], y))
        end
    end

    if !isempty(segs)
        linesegments!(p, segs; color=color, alpha=linealpha, 
            linewidth=linewidth, linestyle = :dot)
        end 
    return nothing
end


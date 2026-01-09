"""
normalize_bivariate(U, V, uref, vref; method=:ecdf, qrange=(0.02,0.98),
                    fixed_u=nothing, fixed_v=nothing, flip_v=false)

Return: (U01, V01, uinfo, vinfo)

- U01, V01 :: Matrix{Float32} in [0,1] (V01 is flipped if flip_v=true)
- uinfo, vinfo :: reference info for electrode mapping:
    * for :ecdf  -> sorted reference samples (Vector{Float32})
    * for others -> [min, max] bounds (Vector{Float32} of length 2)
"""
function normalize_bivariate(U::AbstractArray{<:Real},
                             V::AbstractArray{<:Real},
                             uref::AbstractVector{<:Real},
                             vref::AbstractVector{<:Real};
                             method::Symbol = :robust_minmax,
                             qrange::Tuple{<:Real,<:Real} = (0.02, 0.98),
                             fixed_u::Union{Nothing,Tuple{<:Real,<:Real}} = nothing,
                             fixed_v::Union{Nothing,Tuple{<:Real,<:Real}} = nothing,
                             flip_v::Bool = false)

    # helpers
    ecdf_norm(A, ref) = begin
        vals = sort(filter(isfinite, ref))
        B = similar(A, Float32)
        if isempty(vals)
            fill!(B, 0.5f0); return B, vals
        end
        n = length(vals)
        @inbounds for I in eachindex(A)
            a = A[I]
            B[I] = isfinite(a) ? Float32(searchsortedlast(vals, a) / n) : NaN32
        end
        return B, vals
    end

    minmax_norm(A, ref; bounds=nothing) = begin
        B = similar(A, Float32)
        if bounds === nothing
            vals = filter(isfinite, ref)
            if isempty(vals)
                fill!(B, 0.5f0); return B, Float32[0, 1]
            end
            amin, amax = extrema(vals)
        else
            amin, amax = bounds
        end
        r = max(Float32(amax - amin), eps(Float32))
        @inbounds for I in eachindex(A)
            a = A[I]
            B[I] = isfinite(a) ? Float32(clamp((a - amin) / r, 0, 1)) : NaN32
        end
        return B, Float32[amin, amax]
    end

    quantile_norm(A, ref; qrange=(0.02,0.98)) = begin
        vals = sort(filter(isfinite, ref))
        B = similar(A, Float32)
        if isempty(vals)
            fill!(B, 0.5f0); return B, Float32[0, 1]
        end
        qmin, qmax = quantile(vals, qrange)
        r = max(Float32(qmax - qmin), eps(Float32))
        @inbounds for I in eachindex(A)
            a = A[I]
            B[I] = isfinite(a) ? Float32(clamp((a - qmin) / r, 0, 1)) : NaN32
        end
        return B, Float32[qmin, qmax]
    end

    # choose per-channel normalization
    if method === :ecdf
        U01, uinfo = ecdf_norm(U, uref)
        V01, vinfo = ecdf_norm(V, vref)
    elseif method === :minmax
        U01, uinfo = minmax_norm(U, uref; bounds=fixed_u)
        V01, vinfo = minmax_norm(V, vref; bounds=fixed_v)
    elseif method === :robust_minmax
        U01, uinfo = quantile_norm(U, uref; qrange=qrange)
        V01, vinfo = quantile_norm(V, vref; qrange=qrange)
    else
        @warn "Unknown norm_method=$(method); falling back to :minmax"
        U01, uinfo = minmax_norm(U, uref; bounds=fixed_u)
        V01, vinfo = minmax_norm(V, vref; bounds=fixed_v)
    end

    if flip_v && !isempty(V01)
        V01 = 1 .- V01
    end

    return (U01, V01, uinfo, vinfo)
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



"""
    sample_bivariate(colorbox::AbstractMatrix{<:Colorant}, u::Real, v::Real; mode::Symbol = :nearest)

Sample a color from a **bivariate colormap matrix** `colorbox` at normalized coordinates `(u, v) ∈ [0, 1]^2`.

The function maps:
- `u` → horizontal axis (columns; typically signal/voltage)
- `v` → vertical axis (rows; typically uncertainty/SD)

### Keyword arguments
- `mode::Symbol = :nearest`  
  Sampling strategy:
  - `:nearest` — discrete, blocky appearance. Picks the nearest cell color without interpolation.  
  - `:bilinear` — smooth gradients. Interpolates linearly between surrounding cells in RGB space.

### Returns
`RGBA{Float32}` color corresponding to `(u, v)` in the `colorbox`.

### Notes
- When using `:nearest`, you can optionally snap `u, v` to the centers of the colorbox bins for stronger block segmentation.
- The function assumes `colorbox` is indexed as `[row=v, col=u]`.

### Examples
```julia
# 5×5 bivariate color matrix
colorbox = bivariate_colormatrix_range(n_rows=5, n_cols=5)

# Sample discrete cell color
c1 = sample_bivariate(colorbox, 0.2, 0.7; mode=:nearest)

# Sample smooth interpolated color
c2 = sample_bivariate(colorbox, 0.2, 0.7; mode=:bilinear)
"""
function sample_bivariate(colorbox::AbstractMatrix{<:Colorant}, u::Real, v::Real;
    mode::Symbol=:nearest)
    nrows, ncols = size(colorbox)
    if mode === :nearest
        xi = clamp(round(Int, 1 + u*(ncols-1)), 1, ncols)
        yi = clamp(round(Int, 1 + v*(nrows-1)), 1, nrows)
        c = colorbox[yi, xi]
        C = convert(RGB{Float32}, c)
        return RGBA{Float32}(C.r, C.g, C.b, alpha(c))
    elseif mode === :bilinear
        x = 1 .+ u*(ncols-1)
        y = 1 .+ v*(nrows-1)
        x0 = clamp(floor(Int, x), 1, ncols); x1 = clamp(x0 + 1, 1, ncols)
        y0 = clamp(floor(Int, y), 1, nrows); y1 = clamp(y0 + 1, 1, nrows)
        tx = clamp(x - x0, 0, 1); ty = clamp(y - y0, 0, 1)
        c00 = convert(RGB{Float32}, colorbox[y0, x0])
        c10 = convert(RGB{Float32}, colorbox[y0, x1])
        c01 = convert(RGB{Float32}, colorbox[y1, x0])
        c11 = convert(RGB{Float32}, colorbox[y1, x1])
        C0 = RGB{Float32}((1-tx)*c00.r + tx*c10.r,
            (1-tx)*c00.g + tx*c10.g,
            (1-tx)*c00.b + tx*c10.b)
        C1 = RGB{Float32}((1-tx)*c01.r + tx*c11.r,
            (1-tx)*c01.g + tx*c11.g,
            (1-tx)*c01.b + tx*c11.b)
        C  = RGB{Float32}((1-ty)*C0.r + ty*C1.r,
            (1-ty)*C0.g + ty*C1.g,
            (1-ty)*C0.b + ty*C1.b)
        return RGBA{Float32}(C.r, C.g, C.b, 1)
    else
        error("sample_bivariate: unknown mode $mode")
    end
end

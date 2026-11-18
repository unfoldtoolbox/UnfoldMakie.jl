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
    sample_bivariate(colorbox::AbstractMatrix{<:Colorant}, u::Real, v::Real;
    mode::Symbol=:nearest)

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
```
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

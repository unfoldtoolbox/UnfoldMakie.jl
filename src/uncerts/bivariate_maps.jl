#using ScatteredInterpolation
#import ScatteredInterpolation: interpolate, evaluate 
import TopoPlots: GeomExtrapolation, enclosing_geometry, points2mat
using GeometryBasics: Point2f, Rect2f, decompose


"""
    _mod_uncertainty_rgb(c::Colorant, cs::Float64, dL::Float64) -> RGB

Apply uncertainty-based perceptual modulation to a color.

This helper adjusts a base color's **chroma** and **lightness** in CIELCH space
to represent increasing uncertainty. Typically used inside `bivariate_colormatrix_range`
to build sequential rows that fade or desaturate as uncertainty increases.

CIELH: C = Chroma, I (often dropped) = from International Commission on Illumination (CIE), L = Lightness, C = Chroma, H = Hue angle
LCHab: polar-coordinate version of the CIELAB color space.

Arguments:
- `c`  — Base color (e.g., from the divergent voltage palette).
- `cs` — Chroma scaling factor ∈ [0, 1]; lower values reduce color saturation.
- `dL` — Lightness offset in ΔL*; positive values make the color lighter.

Behavior:
- Converts `c` → `LCHab`.
- Adds `dL` to the lightness channel `L`, clamped to [0, 100].
- Multiplies the chroma channel `C` by `cs`, clamped to [0, 150].
- Keeps hue `H` constant (sets to 0° if undefined).
- Returns the modified color as `RGB`.

Example:
```julia
julia> _mod_uncertainty_rgb(colorant"#2166ac", 0.5, 10)
RGB{Float32}(0.62, 0.69, 0.79)  # lighter and less saturated
```
"""
@inline function _mod_uncertainty_rgb(c::Colorant, cs::Float64, dL::Float64)::RGB
    lch = convert(LCHab, RGB(c))
    L = clamp(lch.l + dL, 0.0, 100.0)
    C = clamp(lch.c * cs, 0.0, 150.0)
    H = isnan(lch.h) ? 0.0 : Float64(lch.h)
    return RGB(LCHab(L, C, H))
end

"""
    bivariate_colormatrix_range(; n_rows=4, n_cols=9,
                           neg=colorant"#2166ac",
                           mid=colorant"white",
                           pos=colorant"#f46d43",
                           chroma_range=(1.0, 0.25),
                           lightness_offsets=(0.0, 15.0),
                           order_uncertainty=:low_to_high,
                           base_cols::Union{Nothing,AbstractVector{<:Colorant}}=nothing)

Build a Matrix{RGB} of size (n_rows × n_cols) for a bivariate colorbox:
- Columns = **voltage** (divergent, blue–white–orange by default).
- Rows    = **uncertainty** (sequential via chroma ↓ and lightness ↑).

Arguments:
- `n_rows`, `n_cols` — number of uncertainty rows and voltage columns.
- `neg`, `mid`, `pos` — endpoints & midpoint of the divergent voltage palette.
- `chroma_range` — (start, end) chroma multipliers across rows (default 1.0→0.25).
- `lightness_offsets` — (start, end) L* offsets across rows (default 0→+15).
- `order_uncertainty` — `:low_to_high` (row 1 = low uncertainty) or `:high_to_low`.
- `base_cols` — optional custom vector of base voltage colors (overrides neg/mid/pos).

Returns: `Matrix{RGB}` with rows=uncertainty, cols=voltage.
"""
function bivariate_colormatrix_range(; n_rows::Int = 4, n_cols::Int = 9,
    neg = colorant"#2166ac", mid = colorant"#f0f0f0", pos = colorant"#f46d43",
    chroma_range::Tuple{Real,Real} = (1.0, 0.25),
    lightness_offsets::Tuple{Real,Real} = (0.0, 15.0),
    order_uncertainty::Symbol = :low_to_high,
    base_cols::Union{Nothing,AbstractVector{<:Colorant}} = nothing,
)::Matrix{RGB}

    # Voltage palette (columns)
    cols =
        isnothing(base_cols) ?
        RGB.(cgrad([neg, mid, pos], n_cols, categorical = true)) :
        RGB.(
            length(base_cols) == n_cols ? base_cols :
            error("length(base_cols) ($(length(base_cols))) must equal n_cols ($n_cols)")
        )

    # Uncertainty ramps (rows)
    cs_vec = collect(range(float(chroma_range[1]), float(chroma_range[2]); length = n_rows))
    dL_vec = collect(
        range(float(lightness_offsets[1]), float(lightness_offsets[2]); length = n_rows),
    )

    if order_uncertainty == :high_to_low
        cs_vec = reverse(cs_vec)
        dL_vec = reverse(dL_vec)
    elseif order_uncertainty != :low_to_high
        @warn "order_uncertainty should be :low_to_high or :high_to_low; using :low_to_high"
    end

    M = Matrix{RGB}(undef, n_rows, n_cols)
    for r = 1:n_rows
        cs, dL = cs_vec[r], dL_vec[r]
        for c = 1:n_cols
            M[r, c] = _mod_uncertainty_rgb(cols[c], cs, dL)
        end
    end
    return M
end


# Linear interpolation between two colors (Lab space → RGB out)
@inline function _lerp_lab(c1::Colorant, c2::Colorant, t::Real)
    a, b = Lab(c1), Lab(c2)
    Lab((1 - t) * a.l + t * b.l,
        (1 - t) * a.a + t * b.a,
        (1 - t) * a.b + t * b.b) |> RGB
end

"""
    bivariate_colormatrix_corners(n_rows, n_cols; top_left, top_right, bot_right, bot_left, mid, order_vertical=:low_to_high)

Generate a **bivariate colormap matrix** where the **vertical axis** represents a sequential (low→high) progression
and the **horizontal axis** represents a diverging (left→right) hue contrast.  
Used for encoding two variables (e.g., signal × uncertainty).

Arguments:
- `n_rows`, `n_cols` — size of the color matrix grid.
- Corner colors (`top_left`, `top_right`, `bot_right`, `bot_left`) — define the hues at each corner.
- `mid` — neutral midpoint color for the horizontal diverging transition.
- `order_vertical` — if `:low_to_high`, sequential dimension increases top→bottom; if `:high_to_low`, reversed.

Returns: `Matrix{RGB{Float32}}` of size `(n_rows, n_cols)`.
"""
function bivariate_colormatrix_corners(
    n_cols::Int, n_rows::Int;
    top_left::Colorant,
    top_right::Colorant,
    bot_right::Colorant,
    bot_left::Colorant,
    mid::Colorant = colorant"#e5e1e4",
    order_vertical::Symbol = :low_to_high,
)
    # Build top and bottom rows with horizontal diverging blend via mid
    us = range(0.0, 1.0; length = n_cols)

    top_row = Vector{RGB{Float32}}(undef, n_cols)
    bottom_row = similar(top_row)

    @inbounds for j = 1:n_cols
        u = us[j]
        if u <= 0.5
            t = u / 0.5
            top_row[j] = RGB{Float32}(_lerp_lab(top_left, mid, t))
            bottom_row[j] = RGB{Float32}(_lerp_lab(bot_left, mid, t))
        else
            t = (u - 0.5) / 0.5
            top_row[j] = RGB{Float32}(_lerp_lab(mid, top_right, t))
            bottom_row[j] = RGB{Float32}(_lerp_lab(mid, bot_right, t))
        end
    end

    # Vertical sequential blend (top → bottom)
    vs = range(0.0, 1.0; length = n_rows)
    colorbox = Array{RGB{Float32}}(undef, n_rows, n_cols)
    @inbounds for i = 1:n_rows
        v = vs[i]
        for j = 1:n_cols
            colorbox[i, j] = RGB{Float32}(_lerp_lab(top_row[j], bottom_row[j], v))
        end
    end

    if order_vertical == :high_to_low
        colorbox = reverse(colorbox, dims = 1)
    end

    return colorbox
end

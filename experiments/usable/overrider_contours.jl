
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
    nL, nA, nB, color, linealpha, linewidth,
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

    cont === nothing && (cont = _BIVAR_FALLBACK_CONTOURS[])
    cont === nothing && (cont = Attributes())

    cont isa Attributes || (cont = Attributes(cont))

    bins = to_value(get(cont, :lab_bins, (8, 8, 8)))
    nL, nA, nB = bins

    color     = get(cont, :color, :black)
    linealpha = get(cont, :linealpha, 0.75)
    linewidth = get(cont, :linewidth, 0.9)

    return (; nL, nA, nB, color, linealpha, linewidth)
end
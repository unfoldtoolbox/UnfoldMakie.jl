include("../plot_fitting/individual_uncert.jl")
include("colorbox_fitting.jl")

using Colors

@inline function _set_lch_lightness_and_chroma(
    c::Colorant,
    L::Real;
    chroma_scale::Real = 1.0,
)
    lch = convert(LCHab, RGB(c))
    H = isnan(lch.h) ? 0.0 : Float64(lch.h)
    return RGB{Float32}(LCHab(
        clamp(Float64(L), 0.0, 100.0),
        clamp(lch.c * Float64(chroma_scale), 0.0, 120.0),
        H,
    ))
end

function _sequential_base_cols(; n_cols::Int = 5, colormap = :viridis)
    grad = cgrad(colormap)
    ts = range(0.0, 1.0; length = n_cols)
    return RGB{Float32}.(get.(Ref(grad), ts))
end

@inline function _lerp_lab_rgb(c1::Colorant, c2::Colorant, t::Real)
    a, b = Lab(c1), Lab(c2)
    return RGB{Float32}(Lab(
        (1 - t) * a.l + t * b.l,
        (1 - t) * a.a + t * b.a,
        (1 - t) * a.b + t * b.b,
    ))
end

"""
    scientific_linear_lightness_colorbox(base_cols;
        n_rows = 5,
        L_left = 18,
        L_right = 88,
        chroma_top = 1.0,
        chroma_bottom = 0.12,
        lightness_top = 0.0,
        lightness_bottom = 16.0,
        order_vertical = :low_to_high,
    )

Build a bivariate range colorbox whose horizontal axis behaves like a sequential
palette rather than a diverging one.

- Columns follow a monotonic left-to-right lightness ramp, similar to `:viridis`.
- Rows still encode uncertainty by gradually reducing chroma and increasing
  lightness.
- The same horizontal lightness profile is reused for every row so the
  left-to-right structure stays stable.
"""
function scientific_linear_lightness_colorbox(
    base_cols::AbstractVector{<:Colorant};
    n_rows::Int = 5,
    L_left::Real = 18,
    L_right::Real = 88,
    chroma_top::Real = 1.0,
    chroma_bottom::Real = 0.12,
    lightness_top::Real = 0.0,
    lightness_bottom::Real = 16.0,
    order_vertical::Symbol = :low_to_high,
)
    n_cols = length(base_cols)

    L_cols = collect(range(float(L_left), float(L_right); length = n_cols))
    chroma_rows = collect(range(float(chroma_top), float(chroma_bottom); length = n_rows))
    dL_rows = collect(range(float(lightness_top), float(lightness_bottom); length = n_rows))

    if order_vertical == :high_to_low
        chroma_rows = reverse(chroma_rows)
        dL_rows = reverse(dL_rows)
    elseif order_vertical != :low_to_high
        @warn "order_vertical should be :low_to_high or :high_to_low; using :low_to_high"
    end

    top_row = [
        _set_lch_lightness_and_chroma(base_cols[j], L_cols[j])
        for j in 1:n_cols
    ]

    out = Matrix{RGB{Float32}}(undef, n_rows, n_cols)
    for i in 1:n_rows
        for j in 1:n_cols
            out[i, j] = _set_lch_lightness_and_chroma(
                top_row[j],
                L_cols[j] + dL_rows[i];
                chroma_scale = chroma_rows[i],
            )
        end
    end

    return out
end

"""
    viridis_range_colorbox(; n_rows = 5, n_cols = 5, colormap = :viridis, kwargs...)

Create a sequential bivariate range colorbox whose x-axis follows a viridis-like
progression and whose y-axis expresses uncertainty through lighter, duller rows.
"""
function viridis_range_colorbox(;
    n_rows::Int = 5,
    n_cols::Int = 5,
    colormap = :viridis,
    kwargs...,
)
    base_cols = _sequential_base_cols(; n_cols = n_cols, colormap = colormap)
    return scientific_linear_lightness_colorbox(
        base_cols;
        n_rows = n_rows,
        kwargs...,
    )
end

colorbox_range_linear = viridis_range_colorbox()

"""
    smooth_corner_colorbox(;
        n_rows = 5,
        n_cols = 5,
        colormap = :viridis,
        top_left = nothing,
        top_right = nothing,
        top_chroma_scale = 1.0,
        top_lightness_shift = 0.0,
        top_left_chroma_scale = nothing,
        top_right_chroma_scale = nothing,
        top_left_lightness_shift = nothing,
        top_right_lightness_shift = nothing,
        order_vertical = :low_to_high,
    )

Build a bivariate corner colorbox with a visible lower viridis edge and
smoothly interpolated opposite-hue colors on the visible upper side.

Unlike the usual corner construction with an explicit neutral midpoint, this
does not force a strong diverging center column. The visible lower side is a
true viridis ramp, while the visible upper corners are derived from hues opposite to the
left and right viridis endpoints.
"""
function smooth_corner_colorbox(;
    n_rows::Int = 5,
    n_cols::Int = 5,
    colormap = :viridis,
    top_left = nothing,
    top_right = nothing,
    top_chroma_scale::Real = 1.0,
    top_lightness_shift::Real = 0.0,
    top_left_chroma_scale = nothing,
    top_right_chroma_scale = nothing,
    top_left_lightness_shift = nothing,
    top_right_lightness_shift = nothing,
    order_vertical::Symbol = :low_to_high,
)
    lerp_lab_rgb(c1::Colorant, c2::Colorant, t::Real) = begin
        a, b = Lab(c1), Lab(c2)
        RGB{Float32}(Lab(
            (1 - t) * a.l + t * b.l,
            (1 - t) * a.a + t * b.a,
            (1 - t) * a.b + t * b.b,
        ))
    end
    opposite_hue_color(c::Colorant; chroma_scale::Real = 1.0, lightness_shift::Real = 0.0) = begin
        lch = convert(LCHab, RGB(c))
        H = isnan(lch.h) ? 0.0 : mod(Float64(lch.h) + 180.0, 360.0)
        L = clamp(lch.l + Float64(lightness_shift), 0.0, 100.0)
        C = clamp(lch.c * Float64(chroma_scale), 0.0, 120.0)
        RGB{Float32}(LCHab(L, C, H))
    end

    grad = cgrad(colormap)
    xs = range(0.0, 1.0; length = n_cols)
    ys = range(0.0, 1.0; length = n_rows)

    lower_row = RGB{Float32}.(get.(Ref(grad), xs))
    left_chroma_scale = isnothing(top_left_chroma_scale) ? top_chroma_scale : top_left_chroma_scale
    right_chroma_scale = isnothing(top_right_chroma_scale) ? top_chroma_scale : top_right_chroma_scale
    left_lightness_shift = isnothing(top_left_lightness_shift) ? top_lightness_shift : top_left_lightness_shift
    right_lightness_shift = isnothing(top_right_lightness_shift) ? top_lightness_shift : top_right_lightness_shift

    upper_left = isnothing(top_left) ?
        opposite_hue_color(
            lower_row[1];
            chroma_scale = left_chroma_scale,
            lightness_shift = left_lightness_shift,
        ) :
        RGB{Float32}(top_left)
    upper_right = isnothing(top_right) ?
        opposite_hue_color(
            lower_row[end];
            chroma_scale = right_chroma_scale,
            lightness_shift = right_lightness_shift,
        ) :
        RGB{Float32}(top_right)

    upper_row = [lerp_lab_rgb(upper_left, upper_right, x) for x in xs]

    colorbox = [
        lerp_lab_rgb(upper_row[j], lower_row[j], y)
        for y in ys, j in 1:n_cols
    ]

    if order_vertical == :low_to_high
        return colorbox
    elseif order_vertical == :high_to_low
        return reverse(colorbox, dims = 1)
    else
        @warn "order_vertical should be :low_to_high or :high_to_low; using :low_to_high"
        return colorbox
    end
end

colorbox_corner_linear = smooth_corner_colorbox(
    top_left_chroma_scale = 0.55,
    top_left_lightness_shift = 40.0,
    top_right_chroma_scale = 0.9,
    top_right_lightness_shift = 6.0,
)

# Range checks:
# plot_colorbox_side_lightness(colorbox_range_linear)
# plot_colorbox_deltaE_neighbors(colorbox_range_linear)
# plot_colorbox_side_perceptual_change(colorbox_range_linear)
# plot_colorbox_side_cumulative_perceptual_change(colorbox_range_linear)
#
# test = load_erp_subject("MMN"; subject = 26, timepoint = 95, condition = 3)
# plot_bivariate_range(
#     test.estimate,
#     test.se;
#     labels = test.labels,
#     uncert_label = "SE",
#     colorbox = colorbox_range_linear,
# )
#
# Corner checks:
# plot_colorbox_side_lightness(colorbox_corner_linear)
# plot_colorbox_deltaE_neighbors(colorbox_corner_linear)
# plot_colorbox_side_perceptual_change(colorbox_corner_linear)
# plot_colorbox_side_cumulative_perceptual_change(colorbox_corner_linear)
#
 plot_bivariate_corner(
    test.estimate,
     test.se;
     labels = test.labels,
     uncert_label = "SE",
     colorbox = colorbox_corner_linear,
 )

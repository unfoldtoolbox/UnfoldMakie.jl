include("../plot_fitting/individual_uncert.jl")

test = load_erp_subject("N170"; subject=12, timepoint = 105,  condition = 3)
test_diff = load_erp_subject("MMN"; subject=26, timepoint = 95,  condition = 3)
p3_11 = load_erp_subject("P3"; subject=11, timepoint = 128,  condition = 1)




colorbox = bivariate_colormatrix_corners(
    5, 5;
    top_left  = colorant"#2166AC",
    top_right = colorant"#F28E2B",
    bot_left  = colorant"#1B9E77",
    bot_right = colorant"#C51B8A",
    mid       = colorant"#F7F4D3",
)

plot_colorbox_side_lightness(colorbox)


c = colorant"#2166AC"
lab = Lab(c)

lab.l   # lightness
lab.a
lab.b

lch = convert(LCHab, c)
lch.l   # lightness



colorbox2 = scientific_lightness_colorbox(
    colorbox;
    L_center = 88,
    L_edge = 48,
    chroma_top = 0.95,
    chroma_bottom = 0.95,
)

plot_colorbox_side_lightness(colorbox2)

plot_bivariate_corner(test.estimate, test.se; labels = test.labels, uncert_label = "SE",
     colorbox = colorbox2
)

plot_bivariate_corner(test.estimate, test.se; labels = test.labels, uncert_label = "SE",
     colorbox = colorbox2, wireframe = true
)

colorbox3 = scientific_lightness_colorbox(
    colorbox;
    L_center = 88,
    L_edge = 48,
    chroma_top = 0.95,
    chroma_bottom = 0.95,
)
plot_colorbox_side_lightness(colorbox3)
plot_bivariate_corner(test.estimate, test.se; labels = test.labels, uncert_label = "SE",
     colorbox = colorbox3
)

# ---------- FINAL RESUlts
test = load_erp_subject("N170"; subject=12, timepoint = 105,  condition = 2)
test_diff = load_erp_subject("MMN"; subject=26, timepoint = 95,  condition = 3)

plot_subject_region_weights(
    "MMN"; subject = 26, timepoint = 96, condition = 3,
)

# old corner
colorbox_c = bivariate_colormatrix_corners(
        5, 5;
        top_left = colorant"#564f9d",
        top_right = colorant"#ec7429",
        bot_right = colorant"#e50a7d",
        bot_left = colorant"#108644",
        mid = colorant"#FFFFBF",          # neutral center for the horizontal diverging
        order_vertical =  :low_to_high,    # top→bottom gets “stronger”
    )
plot_colorbox_side_lightness(colorbox_c)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE")

# new corner
colorbox_corner = scientific_lightness_colorbox(
    colorbox_c;
    L_center = 84,
    L_edge = 48,
    chroma_top = 1.0,
    chroma_bottom = 0.6,
)
plot_colorbox_side_lightness(colorbox_corner)
plot_bivariate_corner(test_diff.estimate, test_diff.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_corner)
hexbox = colorbox_to_hex_matrix(colorbox_corner)
colorbox_corner = RGB{Float32}.(parse.(Colorant, hexbox))
plot_bivariate_corner(test_diff.estimate, test_diff.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_corner)

# old range
colorbox_r = bivariate_colormatrix_range(
    n_rows = 5,
    n_cols = 5,
    neg = colorant"#2166ac",
    mid = colorant"#FFFFBF",
    pos = colorant"#f46d43",
    order_vertical = :low_to_high,
)

plot_colorbox_side_lightness(colorbox_r)
plot_bivariate_range(test_diff.estimate, test_diff.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_r)

# new range
colorbox_range = scientific_lightness_colorbox(
    colorbox_r;
    L_center = 84,
    L_edge = 60,
    chroma_top = 1.0,
    chroma_bottom = 0.75,
)
hexbox = colorbox_to_hex_matrix(colorbox_range)
plot_colorbox_side_lightness(colorbox_range)
plot_bivariate_range(test_diff.estimate, test_diff.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_range)


plot_colorbox_side_perceptual_change(colorbox_two_diverging)
plot_colorbox_side_cumulative_perceptual_change(colorbox_two_diverging)

fig1, fig2, fig3 = checkers(colorbox12)
fig1
fig2
fig3

#####################################################


ΔE_h, ΔE_v = colorbox_deltaE_neighbors(colorbox4)

plot_colorbox_deltaE_neighbors(colorbox4)
plot_colorbox_deltaE_neighbors(colorbox)



colorbox5 = scientific_lightness_colorbox(
    colorbox;
    L_center = 84,
    L_edge = 42,
    chroma_top = 1.0,
    chroma_bottom = 0.15,
)

plot_colorbox_deltaE_neighbors(colorbox5)
plot_colorbox_side_lightness(colorbox5)
plot_bivariate_corner(test.estimate, test.se; labels = test.labels, uncert_label = "SE",
     colorbox = colorbox5, wireframe = true
)


colorbox6 = scientific_lightness_colorbox(
    colorbox;
    L_center = 78,
    L_edge = 42,
    chroma_top = 1.0,
    chroma_bottom = 0.10,
)

function checkers(colorbox)
    fig1 = plot_colorbox_deltaE_neighbors(colorbox)
    fig2 = plot_colorbox_side_lightness(colorbox)
    fig3 = plot_bivariate_corner(
        test.estimate, test.se;
        labels = test.labels,
        uncert_label = "SE",
        colorbox = colorbox,
        wireframe = true,
    )

    return fig1, fig2, fig3
end
fig1, fig2, fig3 = checkers(colorbox6)
fig1
fig2
fig3

############ manually choosing colors

deltaE(c1, c2) = colordiff(Lab(c1), Lab(c2); metric = DE_2000())
function corner_deltas(colorbox)
    nrow, ncol = size(colorbox)

    top    = 1
    bottom = nrow
    left   = 1
    center = cld(ncol, 2)
    right  = ncol

    return (
        left   = deltaE(colorbox[top, left],   colorbox[bottom, left]),
        center = deltaE(colorbox[top, center], colorbox[bottom, center]),
        right  = deltaE(colorbox[top, right],  colorbox[bottom, right]),
    )
end

c_blue  = colorant"#7167B9"
c_green = colorant"#477D56"

# Perceptual difference

deltaE(c_blue, c_green)


c_orange =  colorant"#C04F00"
c_purple = colorant"#B74E75"

deltaE(c_orange, c_purple)


c_orange_new = colorant"#D77900"
c_purple     = colorant"#B74E75"

deltaE(c_orange_new, c_purple)
lab_endpoint_report(c_blue, c_green)
lab_endpoint_report(c_orange_new, c_purple)

colorbox_c = bivariate_colormatrix_corners(
        5, 5;
        top_left =  colorant"#477D56",
        top_right = colorant"#B74E75",
        bot_right = colorant"#D77900",
        bot_left =  colorant"#7167B9",
        mid = colorant"#FFFFBF",          # neutral center for the horizontal diverging
        order_vertical =  :low_to_high,    # top→bottom gets “stronger”
    )
plot_colorbox_side_lightness(colorbox_c)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE")
plot_colorbox_deltaE_neighbors(colorbox_c)
corner_deltas(colorbox_c)
plot_colorbox_side_perceptual_change(colorbox_c)
plot_colorbox_side_cumulative_perceptual_change(colorbox_c)
# new corner

colorbox_corner = scientific_lightness_colorbox(
    colorbox_c;
    L_center = 84,
    L_edge = 48,
    chroma_top = 1.0,
    chroma_bottom = 0.6,
)
plot_colorbox_side_lightness(colorbox_corner)
plot_bivariate_corner(test_diff.estimate, test_diff.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_corner)
corner_deltas(colorbox_c)
plot_colorbox_side_perceptual_change(colorbox_c)
#hexbox = colorbox_to_hex_matrix(colorbox_corner)
#colorbox_corner = RGB{Float32}.(parse.(Colorant, hexbox))
#plot_bivariate_corner(test_diff.estimate, test_diff.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_corner)





using Colors

@inline function _lerp_lab(c1::Colorant, c2::Colorant, t::Real)
    a, b = Lab(c1), Lab(c2)
    return RGB{Float32}(Lab(
        (1 - t) * a.l + t * b.l,
        (1 - t) * a.a + t * b.a,
        (1 - t) * a.b + t * b.b,
    ))
end

top_row = [
    colorant"#86B96B",  # light green
    colorant"#B9CA58",  # yellow-green
    colorant"#D7D65B",  # yellow
    colorant"#DEA044",  # yellow-orange
    colorant"#D86D24",  # orange
]

bottom_row = [
    colorant"#2F6B4F",  # dark green
    colorant"#216D78",  # teal-blue
    colorant"#315AA8",  # blue
    colorant"#674A9D",  # indigo
    colorant"#9A3E83",  # purple
]

colorbox_flipped = [
    _lerp_lab(top_row[j], bottom_row[j], t)
    for t in range(0, 1; length = 5), j in 1:5
]


plot_colorbox_side_lightness(colorbox_flipped)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_flipped)
plot_colorbox_deltaE_neighbors(colorbox_flipped)
corner_deltas(colorbox_flipped)
plot_colorbox_side_perceptual_change(colorbox_flipped)
plot_colorbox_side_cumulative_perceptual_change(colorbox_flipped)



top_row2 = [
    colorant"#98C86B",  # light green
    colorant"#C2D55C",  # yellow-green
    colorant"#E0D65E",  # yellow
    colorant"#E19D3A",  # orange
    colorant"#DD671A",  # strong orange
]

bottom_row2 = [
    colorant"#1F5B49",  # dark green  -> stronger left contrast
    colorant"#5D7B45",  # moss green
    colorant"#C7C66D",  # olive-yellow -> much closer to top center
    colorant"#6F5496",  # indigo
    colorant"#922F86",  # deep purple  -> stronger right contrast
]

colorbox_flipped2 = [
    _lerp_lab(top_row2[j], bottom_row2[j], t)
    for t in range(0, 1; length = 5), j in 1:5
]

plot_colorbox_side_lightness(colorbox_flipped2)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_flipped2)
plot_colorbox_deltaE_neighbors(colorbox_flipped2)
corner_deltas(colorbox_flipped2)
plot_colorbox_side_perceptual_change(colorbox_flipped2)
plot_colorbox_side_cumulative_perceptual_change(colorbox_flipped2)



function four_corner_colorbox(;
    n::Int = 5,
    top_left     = colorant"#D8D35F",  # yellow
    top_right    = colorant"#C84D3A",  # red
    bottom_left  = colorant"#4F8A5B",  # green
    bottom_right = colorant"#4F66B0",  # blue
)
    # top edge: yellow → red
    # bottom edge: green → blue
    xs = range(0, 1; length = n)

    top_row = [
        _lerp_lab(top_left, top_right, x)
        for x in xs
    ]

    bottom_row = [
        _lerp_lab(bottom_left, bottom_right, x)
        for x in xs
    ]

    # vertical interpolation between top and bottom rows
    ys = range(0, 1; length = n)

    colorbox = [
        _lerp_lab(top_row[j], bottom_row[j], y)
        for y in ys, j in 1:n
    ]

    return colorbox
end

colorbox_opposite = four_corner_colorbox()

plot_colorbox_side_lightness(colorbox_opposite)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_opposite)
plot_colorbox_deltaE_neighbors(colorbox_opposite)
corner_deltas(colorbox_opposite)
plot_colorbox_side_perceptual_change(colorbox_opposite)
plot_colorbox_side_cumulative_perceptual_change(colorbox_opposite)

lab_endpoint_report(colorant"#D8D35F", colorant"#4F8A5B") # yellow-green
lab_endpoint_report(colorant"#C84D3A", colorant"#4F66B0") # red-blue

colorbox_equal_hue = four_corner_colorbox(
    n = 5,
    top_left     = colorant"#C29750",
    top_right    = colorant"#E07FAD",
    bottom_left  = colorant"#30B18E",
    bottom_right = colorant"#39A6EA",
)

plot_colorbox_side_lightness(colorbox_equal_hue)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_equal_hue)
plot_colorbox_deltaE_neighbors(colorbox_equal_hue)
corner_deltas(colorbox_equal_hue)
plot_colorbox_side_perceptual_change(colorbox_equal_hue)
plot_colorbox_side_cumulative_perceptual_change(colorbox_equal_hue)



function diverging_row(left::Colorant, mid::Colorant, right::Colorant; n::Int = 5)
    xs = range(0, 1; length = n)

    return [
        x <= 0.5 ?
            _lerp_lab(left, mid, x / 0.5) :
            _lerp_lab(mid, right, (x - 0.5) / 0.5)
        for x in xs
    ]
end

#= function two_diverging_rows_colorbox(;
    n::Int = 5,

    top_right     = colorant"#30B18E",  # teal-green
    top_mid      = colorant"#D2D6B8",  # pale cool beige / muted yellow-green center
    top_left    = colorant"#39A6EA",  # sky blue / cyan-blue


    bottom_right  = colorant"#C29750",  # ochre / muted yellow-brown
    bottom_mid   = colorant"#E3DDB8",  # pale warm beige / low-chroma center
    bottom_left = colorant"#E07FAD",  # soft pink / magenta-rose
)
    top_row = diverging_row(top_left, top_mid, top_right; n = n)
    bottom_row = diverging_row(bottom_left, bottom_mid, bottom_right; n = n)

    ys = range(0, 1; length = n)

    colorbox = [
        _lerp_lab(top_row[j], bottom_row[j], y)
        for y in ys, j in 1:n
    ]

    return colorbox
end =#

function two_diverging_rows_colorbox(;
    n::Int = 5,

    bottom_right     =  colorant"#E07FAD",  # red-pink / magenta
    bottom_mid      = colorant"#E3DDB8",  # quiet pale center
    bottom_left    = colorant"#C29750",  # yellow / ochre

    top_right  = colorant"#30B18E",  # green / teal
    top_mid   = colorant"#D2D6B8",  # similar center, slightly cooler/darker
    top_left = colorant"#39A6EA",  # blue
)
    top_row = diverging_row(top_left, top_mid, top_right; n = n)
    bottom_row = diverging_row(bottom_left, bottom_mid, bottom_right; n = n)

    ys = range(0, 1; length = n)

    colorbox = [
        _lerp_lab(top_row[j], bottom_row[j], y)
        for y in ys, j in 1:n
    ]

    return colorbox
end

colorbox_two_diverging = two_diverging_rows_colorbox()
colorbox_two_diverging_s = scientific_lightness_colorbox(
    colorbox_two_diverging;
    L_center = 84,
    L_edge = 60,
    chroma_top = 1.0,
    chroma_bottom = 0.75,
)
colorbox_to_hex_matrix(colorbox_two_diverging_s)

#= plot_colorbox_side_lightness(colorbox_two_diverging)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_two_diverging)
plot_colorbox_deltaE_neighbors(colorbox_two_diverging)
corner_deltas(colorbox_two_diverging)
plot_colorbox_side_perceptual_change(colorbox_two_diverging)
plot_colorbox_side_cumulative_perceptual_change(colorbox_two_diverging)

plot_bivariate_corner(p3_11.estimate, test.se; labels = p3_11.labels, uncert_label = "SE", colorbox = colorbox_two_diverging)
 =#
colorbox_to_hex_matrix(colorbox_two_diverging_s)
plot_colorbox_side_lightness(colorbox_two_diverging_s)
plot_bivariate_corner(test_diff.estimate, test.se; labels = test_diff.labels, uncert_label = "SE", colorbox = colorbox_two_diverging_s)
plot_bivariate_corner(p3_11.estimate, test.se; labels = p3_11.labels, uncert_label = "SE", colorbox = colorbox_two_diverging_s)
plot_colorbox_deltaE_neighbors(colorbox_two_diverging_s)
corner_deltas(colorbox_two_diverging_s)
plot_colorbox_side_perceptual_change(colorbox_two_diverging_s)
plot_colorbox_side_cumulative_perceptual_change(colorbox_two_diverging_s)

plot_colorbox_side_perceptual_change(colorbox_two_diverging)
plot_colorbox_side_cumulative_perceptual_change(colorbox_two_diverging)

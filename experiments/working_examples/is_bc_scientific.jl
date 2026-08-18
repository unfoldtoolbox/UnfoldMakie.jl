test = load_erp_subject("N170"; subject=12, timepoint = 105,  condition = 3)
test_diff = load_erp_subject("MMN"; subject=26, timepoint = 95,  condition = 3)

function plot_colorbox_side_lightness(colorbox::AbstractMatrix{<:Colorant})
    n_rows, n_cols = size(colorbox)

    sides = (
        top    = collect(colorbox[1, :]),
        bottom = collect(colorbox[n_rows, :]),
        left   = collect(colorbox[:, 1]),
        right  = collect(colorbox[:, n_cols]),
    )

    styles = (
        top    = :solid,
        bottom = :dash,
        left   = :dot,
        right  = :dashdot,
    )

    # precompute lightness values
    Lvals = Dict(
        side => [Lab(c).l for c in cols]
         for (side, cols) in Base.pairs(sides)
    )

    # common y-limits for easier comparison
    allL = reduce(vcat, values(Lvals))
    ylims_all = (floor(minimum(allL) - 2), ceil(maximum(allL) + 2))

    fig = Figure(size = (900, 700))

    side_order = [:top, :bottom, :left, :right]
    positions = [(1, 1), (1, 2), (2, 1), (2, 2)]

    axes = Dict{Symbol, Axis}()

    for (side, pos) in zip(side_order, positions)
        ax = Axis(
            fig[pos...],
            title = string(side),
            xlabel = "Position along side",
            ylabel = "CIELAB lightness L*",
            limits = (nothing, ylims_all),
        )
        axes[side] = ax

        cols = sides[side]
        L = Lvals[side]
        x = 1:length(L)

        lines!(
            ax, x, L;
            color = (:black, 0.6),
            linewidth = 3,
            linestyle = styles[side],
        )

        scatter!(
            ax, x, L;
            color = cols,
            markersize = 24,
            strokecolor = :black,
            strokewidth = 1.2,
        )
    end

    # optional: link all y axes
    linkyaxes!(axes[:top], axes[:bottom], axes[:left], axes[:right])

    colgap!(fig.layout, 20)
    rowgap!(fig.layout, 20)

    return fig
end


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


"""
    scientific_lightness_colorbox(colorbox;
        L_center = 88,
        L_edge = 48,
        chroma_scale = 1.0,
    )

Modify a bivariate colorbox so that:
- horizontal sides have symmetric diverging lightness
- vertical sides interpolate smoothly between top and bottom
- original hues are approximately preserved

# Keyword arguments

- `L_center = 84`: Target CIELAB lightness for the center column.
  Higher values make the neutral midpoint brighter.

- `L_edge = 42`: Target CIELAB lightness for the outer columns.
  Lower values make the negative and positive extremes darker.

- `chroma_rows = nothing`: Optional explicit chroma scaling vector with one
  value per row. If provided, it overrides `chroma_top` and `chroma_bottom`.

- `chroma_top = 1.0`: Chroma multiplier for the first row. Full color.

- `chroma_bottom = 0.15`: Chroma multiplier for the last row. Duller colors.
"""
function scientific_lightness_colorbox(
    colorbox::AbstractMatrix{<:Colorant};
    L_center = 84,
    L_edge = 42,
    chroma_rows = nothing,
    chroma_top = 1.0,
    chroma_bottom = 0.15,
)
    n_rows, n_cols = size(colorbox)
    center_col = (n_cols + 1) / 2

    # same horizontal lightness profile for every row
    function horizontal_L(j)
        t = abs(j - center_col) / (center_col - 1)
        return (1 - t) * L_center + t * L_edge
    end

    out = Matrix{RGB{Float32}}(undef, n_rows, n_cols)

    for i in 1:n_rows
        v = n_rows == 1 ? 0.0 : (i - 1) / (n_rows - 1)

        # uncertainty effect: reduce chroma vertically
        if isnothing(chroma_rows)
            v = n_rows == 1 ? 0.0 : (i - 1) / (n_rows - 1)
            chroma_factor = (1 - v) * chroma_top + v * chroma_bottom
        else
            chroma_factor = chroma_rows[i]
        end

        for j in 1:n_cols
            lch = convert(LCHab, RGB(colorbox[i, j]))

            L = horizontal_L(j)
            C = clamp(lch.c * chroma_factor, 0, 120)
            H = isnan(lch.h) ? 0.0 : lch.h

            out[i, j] = RGB{Float32}(LCHab(L, C, H))
        end
    end

    return out
end

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
    colorbox;
    L_center = 84,
    L_edge = 48,
    chroma_top = 1.0,
    chroma_bottom = 0.6,
)
plot_colorbox_side_lightness(colorbox_corner)
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
plot_bivariate_range(test.estimate, test.se; labels = test.labels, uncert_label = "SE", colorbox = colorbox_r)

# new range
colorbox_range = scientific_lightness_colorbox(
    colorbox_r;
    L_center = 84,
    L_edge = 60,
    chroma_top = 1.0,
    chroma_bottom = 0.75,
)

plot_colorbox_side_lightness(colorbox_range)
plot_bivariate_range(test.estimate, test.se; labels = test.labels, uncert_label = "SE", colorbox = colorbox_range)

fig1, fig2, fig3 = checkers(colorbox12)
fig1
fig2
fig3

#####################################################

# simple CIELAB distance
function deltaE(c1, c2)
    colordiff(Lab(c1), Lab(c2); metric = DE_2000())
end

function colorbox_deltaE_neighbors(colorbox::AbstractMatrix{<:Colorant})
    n_rows, n_cols = size(colorbox)

    ΔE_h = [
        deltaE(colorbox[i, j], colorbox[i, j+1])
        for i in 1:n_rows, j in 1:(n_cols-1)
    ]

    ΔE_v = [
        deltaE(colorbox[i, j], colorbox[i+1, j])
        for i in 1:(n_rows-1), j in 1:n_cols
    ]

    return ΔE_h, ΔE_v
end

function plot_colorbox_deltaE_neighbors(colorbox::AbstractMatrix{<:Colorant})
    ΔE_h, ΔE_v = colorbox_deltaE_neighbors(colorbox)
    n_rows, n_cols = size(colorbox)

    fig = Figure(size = (850, 360))
    vmin = 0
    vmax = maximum(vcat(vec(ΔE_h), vec(ΔE_v)))

    ax1 = Axis(fig[1, 1], title = "Horizontal ΔE", xlabel = "Column difference", ylabel = "Row",
        xticks = 1:(n_cols - 1), yticks = 1:n_rows)

    hm1 = heatmap!(ax1, 1:(n_cols - 1), 1:n_rows, ΔE_h; colorrange = (vmin, vmax))

    ax2 = Axis(fig[1, 3], title = "Vertical ΔE", xlabel = "Column", ylabel = "Row difference",
        xticks = 1:n_cols, yticks = 1:(n_rows - 1))

    hm2 = heatmap!(ax2, 1:n_cols, 1:(n_rows - 1), ΔE_v; colorrange = (vmin, vmax))

    Colorbar(fig[1, 2], hm1)
    Colorbar(fig[1, 4], hm2; label = "Perceptual difference (ΔE)")

    return fig
end

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


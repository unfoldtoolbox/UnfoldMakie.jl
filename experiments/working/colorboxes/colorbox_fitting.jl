
function colorbox_to_hex_matrix(cb)
    return ["#" * hex(RGB(c)) for c in cb]
end



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

using Colors

deltaE2000(c1, c2) = colordiff(Lab(c1), Lab(c2); metric = DE_2000())

function plot_colorbox_side_perceptual_change(colorbox::AbstractMatrix{<:Colorant})
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

    # precompute perceptual step sizes ΔE2000 between neighboring colours
    ΔEvals = Dict(
        side => [deltaE2000(cols[i], cols[i + 1]) for i in 1:(length(cols) - 1)]
        for (side, cols) in Base.pairs(sides)
    )

    # use the second color of each pair for the scatter markers
    pointcols = Dict(
        side => cols[2:end]
        for (side, cols) in Base.pairs(sides)
    )

    # common y-limits for easier comparison
    allΔE = reduce(vcat, values(ΔEvals))
    ylims_all = (0, ceil(maximum(allΔE) + 2))

    fig = Figure(size = (900, 700))

    side_order = [:top, :bottom, :left, :right]
    positions = [(1, 1), (1, 2), (2, 1), (2, 2)]

    axes = Dict{Symbol, Axis}()

    for (side, pos) in zip(side_order, positions)
        ax = Axis(
            fig[pos...],
            title = string(side),
            xlabel = "Step along side",
            ylabel = "Perceptual change ΔE2000",
            limits = (nothing, ylims_all),
        )
        axes[side] = ax

        ΔE = ΔEvals[side]
        x = 1:length(ΔE)

        lines!(
            ax, x, ΔE;
            color = (:black, 0.6),
            linewidth = 3,
            linestyle = styles[side],
        )

        scatter!(
            ax, x, ΔE;
            color = pointcols[side],
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


function plot_colorbox_side_cumulative_perceptual_change(colorbox::AbstractMatrix{<:Colorant})
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

    cumΔEvals = Dict(
        side => begin
            cols = sides[side]
            steps = [deltaE2000(cols[i], cols[i + 1]) for i in 1:(length(cols) - 1)]
            vcat(0.0, cumsum(steps))
        end
        for side in Base.keys(sides)
    )

    allcumΔE = reduce(vcat, values(cumΔEvals))

    ymax = maximum(allcumΔE)
    ypad = max(5, 0.08 * ymax)

    ylims_all = (-ypad / 2, ceil(ymax + ypad))

    max_n = maximum(length.(values(sides)))
    xlims_all = (0.65, max_n + 0.35)

    fig = Figure(size = (900, 700))

    side_order = [:top, :bottom, :left, :right]
    positions = [(1, 1), (1, 2), (2, 1), (2, 2)]

    axes = Dict{Symbol, Axis}()

    for (side, pos) in zip(side_order, positions)
        ax = Axis(
            fig[pos...],
            title = string(side),
            xlabel = "Position along side",
            ylabel = "Cumulative perceptual change ΔE2000",
            limits = (xlims_all, ylims_all),
            xticks = 1:length(sides[side]),
        )
        axes[side] = ax

        cols = sides[side]
        cumΔE = cumΔEvals[side]
        x = 1:length(cumΔE)

        lines!(
            ax, x, cumΔE;
            color = (:black, 0.6),
            linewidth = 3,
            linestyle = styles[side],
        )

        scatter!(
            ax, x, cumΔE;
            color = cols,
            markersize = 24,
            strokecolor = :black,
            strokewidth = 1.2,
        )
    end

    linkyaxes!(axes[:top], axes[:bottom], axes[:left], axes[:right])

    colgap!(fig.layout, 20)
    rowgap!(fig.layout, 20)

    return fig
end


function lab_endpoint_report(c1::Colorant, c2::Colorant)
    l1 = Lab(c1)
    l2 = Lab(c2)

    h1 = LCHab(c1)
    h2 = LCHab(c2)

    Δh = abs(h2.h - h1.h)
    Δh = min(Δh, 360 - Δh)

    return (
        ΔE = deltaE2000(c1, c2),
        ΔL = l2.l - l1.l,
        Δa = l2.a - l1.a,
        Δb = l2.b - l1.b,
        hue1 = h1.h,
        hue2 = h2.h,
        Δhue = Δh,
        chroma1 = h1.c,
        chroma2 = h2.c,
    )
end
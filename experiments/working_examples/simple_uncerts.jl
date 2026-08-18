dat, positions = TopoPlots.example_data()
vec_estimate = dat[:, 340, 1];
vec_uncert = dat[:, 340, 2];


begin
    f = Figure()
    ax = Axis(
        f[1, 1:2],
        title = "Time windows [340 ms]",
        titlesize = 24,
        titlealign = :center,
    )

    hidedecorations!(ax, label = false)
    hidespines!(ax)
    plot_topoplot!(
        f[1, 1],
        vec_estimate;
        positions = positions,
        visual = (; contours = false),
        axis = (; xlabel = ""),
        colorbar = (;
            label = "Voltage [µV]",
            labelsize = 24,
            ticklabelsize = 18,
            vertical = false,
            width = 180,
        ),
    )
    plot_topoplot!(
        f[1, 2],
        vec_uncert;
        positions = positions,
        visual = (; colormap = (:viridis), contours = false),
        axis = (; xlabel = "", xlabelsize = 24, ylabelsize = 24),
        colorbar = (;
            label = "Standard deviation",
            labelsize = 24,
            ticklabelsize = 18,
            vertical = false,
            width = 180,
        ),
    )
    f
end

begin
    f = Figure()
    ax = Axis(f[1,1], title = "categorical markers on plot", titlesize = 18, titlealign = :left)
    hidedecorations!(ax, label = false); hidespines!(ax)
    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    uncert_scaled = uncert_norm * 30 .+ 10

    plot_topoplot!(
        f[1:4, 1],
        vec_estimate;
        positions,
        axis = (; xlabel = "Time point [340 ms]", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (;
                markersize = uncert_scaled,
                color = :transparent,
                strokecolor = :black,
                strokewidth = uncert_scaled .* 0.25,
            )
        ),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )
    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))
    markerlables = round.(range(extrema(vec_uncert)...; length = 5); digits = 2)

    group_size = [
        MarkerElement(
            marker = :circle,
            color = :transparent,
            strokecolor = :black,
            strokewidth = ms ÷ 5,
            markersize = ms,
        ) for ms in markersizes
    ]
    Legend(
        f[5, 1],
        group_size,
        ["$ms" for ms in markerlables],
        "Standard\ndeviation",
        patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8),
        framevisible = false,
        labelsize = 18,
        titlesize = 20,
        orientation = :horizontal,
        titleposition = :left,
        margin = (90, 0, 0, 0),
    )
    f
end


# continous case

begin

    f = Figure()
    ax = Axis(f[1,1], title = "continous markers on plot", titlesize = 18, titlealign = :left)
    hidedecorations!(ax, label = false); hidespines!(ax)
    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    uncert_scaled = uncert_norm * 30 .+ 10

    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))
    markerlables = round.(range(extrema(vec_uncert)...; length = 5); digits = 2)
    quantized_sizes = [
        markersizes[argmin(abs.(markersizes .- u))]
        for u in uncert_scaled
    ]

    plot_topoplot!(
        f[1:4, 1],
        vec_estimate;
        positions,
        axis = (; xlabel = "Time point [340 ms]", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (;
                markersize = quantized_sizes,
                color = :transparent,
                strokecolor = :black,
                strokewidth = quantized_sizes .* 0.25,
            )
        ),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )

    group_size = [
        MarkerElement(
            marker = :circle,
            color = :transparent,
            strokecolor = :black,
            strokewidth = ms ÷ 5,
            markersize = ms,
        ) for ms in markersizes
    ]
    Legend(
        f[5, 1],
        group_size,
        ["$ms" for ms in markerlables],
        "Standard\ndeviation",
        patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8),
        framevisible = false,
        labelsize = 18,
        titlesize = 20,
        orientation = :horizontal,
        titleposition = :left,
        margin = (90, 0, 0, 0),
    )
    f
end
# countmap(quantized_sizes)

begin
    f = Figure()
    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    rotations = -uncert_norm .* π # radians in [-2π, 0], negaitve - clockwise rotation

    arrow_symbols = ['↑', '↗', '→', '↘', '↓'] # 5 levels of uncertainty

    angles = range(extrema(vec_uncert)...; length = 5)
    labels = ["$(round(a, digits = 2))" for a in angles] # correspons to uncertainty levels

    plot_topoplot!(
        f[1:6, 1],
        vec_estimate;
        positions,
        topo_attributes = (;
            label_scatter = (;
                markersize = 20,
                marker = '↑',
                color = :gray,
                strokecolor = :black,
                strokewidth = 1,
                rotation = rotations,
            )
        ),
        axis = (; xlabel = "Time point [50 ms]", xlabelsize = 24, ylabelsize = 24),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )

    mgroup = [
        MarkerElement(marker = sym, color = :black, markersize = 20) for
        sym in arrow_symbols
    ]

    Legend(
        f[7, 1],
        mgroup,
        labels,
        "Standard\ndeviation";
        patchlabelsize = 14,
        framevisible = false,
        labelsize = 18,
        titlesize = 20,
        orientation = :horizontal,
        titleposition = :left,
        margin = (90, 0, 0, 0),
    )
    f
end


begin
    f = Figure()
    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    uncert_scaled = uncert_norm * 30 .+ 10
    n = length(positions)
    ms = Vec2f.(fill(30.0f0, n), uncert_scaled)              # Vector{Vec2f}

    plot_topoplot!(
        f[1:4, 1],
        vec_estimate;
        positions,
        axis = (; xlabel = "Time point [340 ms]", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (; marker = Rect, markersize = ms)#, #color = :transparent, strokecolor = :black,         
            # strokewidth = uncert_scaled .* 0.25 )
        ),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )
    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))
    #= 
        group_size = [MarkerElement(
            marker = :Rect, 
            color = :transparent, strokecolor = :black, strokewidth = ms ÷ 5, 
            markersize = ms) for ms in markersizes]
        Legend(f[5, 1], group_size, ["$ms" for ms in markersizes], "Standard\ndeviation", 
            patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8), framevisible = false, 
            labelsize = 18, titlesize = 20,
            orientation = :horizontal, titleposition = :left, margin = (90,0,0,0)) =#
    f
end



begin
    f = Figure()
    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    w_min, w_max = 0.03, 0.18              # tune: bar width range in axis/data units
    widths = w_min .+ uncert_norm .* (w_max - w_min)

    # constant bar height (data units)
    h_bar = 0.06
    # Vector{Vec2f}

    plot_topoplot!(
        f[1:4, 1],
        vec_estimate;
        positions,
        axis = (; xlabel = "Time point [340 ms]", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (;
                marker = Rect,
                markersize = [(w, h_bar) for w in widths],
                color = :transparent,
                strokecolor = :black,
                strokewidth = uncert_scaled .* 0.25,
            )
        ),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )
    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))
    #= 
        group_size = [MarkerElement(
            marker = :Rect, 
            color = :transparent, strokecolor = :black, strokewidth = ms ÷ 5, 
            markersize = ms) for ms in markersizes]
        Legend(f[5, 1], group_size, ["$ms" for ms in markersizes], "Standard\ndeviation", 
            patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8), framevisible = false, 
            labelsize = 18, titlesize = 20,
            orientation = :horizontal, titleposition = :left, margin = (90,0,0,0)) =#
    f
end

function _percentile(p::Real, v::AbstractVector)
    n = length(v)
    n == 0 && throw(ArgumentError("percentile of empty collection"))
    s = sort(v)
    idx = clamp(ceil(Int, p * n), 1, n)
    return s[idx]
end

begin
    f = Figure(; resolution = (900, 650))

    # main grid of the figure
    gf = f[1, 1] = GridLayout()

    # subgrid only for the 3 topoplots
    pTopos = GridLayout()
    gf[1:2, 1:3] = pTopos

    pA  = pTopos[1, 2]
    pB  = pTopos[2, 1]
    pC  = pTopos[2, 3]
    pcb = gf[:, 4]              # colorbar spans both rows

    lims = begin
        p01 = _percentile(0.01, vec_estimate)
        p99 = _percentile(0.99, vec_estimate)
        m = max(abs(p01), abs(p99))
        Float32.((-m, m))
    end

    visual = (; limits = lims, colormap = cgrad(:RdBu, 10; categorical = true, rev = true))

    ticks5 = begin
        lo, hi = visual.limits
        pos = Float32[lo, lo/2, 0f0, hi/2, hi]                 # exact positions
        lab = string.(round.(Float64.(pos); sigdigits = 2))    # pretty labels only
        (pos, lab)
    end

    plot_topoplot!(
        pA, vec_estimate;
        positions = positions,
        axis = (; xlabelsize = 24, xlabel = "Mean"),
        layout = (; use_colorbar = false),
        visual = visual,
    )

    plot_topoplot!(
        pB, vec_estimate .- vec_uncert;
        positions = positions,
        axis = (; xlabelsize = 24, xlabel = "Mean - SE"),
        layout = (; use_colorbar = false),
        visual = visual,
    )

    plot_topoplot!(
        pC, vec_estimate .+ vec_uncert;
        positions = positions,
        axis = (; xlabelsize = 24, xlabel = "Mean + SE"),
        layout = (; use_colorbar = false),
        visual = visual,
    )

    Colorbar(
        pcb;
        colormap = visual.colormap,
        limits   = visual.limits,
        ticks    = ticks5,
        label = "Voltage [µV]",
        labelsize = 24,
        ticklabelsize = 18,
        vertical = true,
        height = 300,
        flipaxis = true,
        labelrotation = -π/2,
    )

    # --- spacing control (ONLY affects the topoplots subgrid) ---
    rowgap!(pTopos, -90)
    colgap!(pTopos, -90)

    # optional: make colorbar column tighter
    colgap!(gf, 10)  # try 0..20
    # optional: control relative column widths (topos vs colorbar)
    colsize!(gf, 4, Auto(0.15))  # try Auto(0.12..0.25)

    f
end

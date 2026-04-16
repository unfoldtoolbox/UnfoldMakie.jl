using Base: padding
using UnfoldSim
using LinearAlgebra
using ColorSchemes
using Animations
include("../usable/bivariate_maps.jl")
include("../usable/overrider.jl")
include("../usable/overrider_bivariate.jl")
include("../usable/vsp_sup.jl")

test = load_erp_subject("P3"; subject=11, timepoint=128, condition=1)

function plot_adjacent!(
    f::Union{GridPosition, GridLayout, Figure},
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    enable_contour=true,
    uncert_label="Uncertainty",
    BG=:white,
)
    gl = f isa GridLayout ? f : f isa Figure ? (f[1, 1] = GridLayout()) : (f[] = GridLayout())

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                (;)

    plot_topoplot!(
        gl[1, 1],
        vec_estimate;
        topo_args...,
        visual = (;
            contours = enable_contour,
            clip = false,
            colormap = cgrad(:RdYlBu, 10; categorical=true, rev=true),
        ),
        axis = (;
            xlabel = "",
            xautolimitmargin = (0.02, 0.02),
            yautolimitmargin = (0.03, -0.01),
        ),
        topo_axis = (; backgroundcolor = BG),
        colorbar = (;
            label = "Voltage [µV]",
            labelsize = 24,
            ticklabelsize = 18,
            vertical = false,
            position = :bottom,
            width = 180,
        ),
    )

    plot_topoplot!(
        gl[1, 2],
        vec_uncert;
        topo_args...,
        visual = (;
            colormap = cgrad(:viridis, 10; categorical=true),
            contours = enable_contour,
        ),
        axis = (;
            xlabel = "",
            xlabelsize = 24,
            ylabelsize = 24,
        ),
        topo_axis = (; backgroundcolor = BG),
        colorbar = (;
            label = uncert_label,
            labelsize = 24,
            ticklabelsize = 18,
            vertical = false,
            position = :bottom,
            width = 180,
        ),
    )

    return gl
end

function plot_adjacent(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_adjacent!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

test = load_erp_subject("MMN"; subject=20, timepoint=96, condition=1)
plot_adjacent(test.estimate, test.se; labels = test.labels, uncert_label = "SE")

function plot_bivariate_corner!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "SD",
    order_vertical = :low_to_high
)
    gl = f isa Figure ? f.layout :
         f isa GridLayout ? f :
         (f[] = GridLayout())

    n_cb = 5
    colorbox = bivariate_colormatrix_corners(
        n_cb, n_cb;
        top_left = colorant"#564f9d",
        top_right = colorant"#ec7429",
        bot_right = colorant"#e50a7d",
        bot_left = colorant"#108644",
        mid = colorant"#FFFFBF",          # neutral center for the horizontal diverging
        order_vertical = order_vertical,     # top→bottom gets “stronger”
    )

    xticks = round.(collect(range(UnfoldMakie._topo_range_from_values(vec_estimate)...; length = n_cb)), digits = 2)
    yticks = (round.(collect(range(extrema(vec_uncert)...; length = n_cb)), digits = 2))

    label_inds_x = [1, 3, n_cb]
    label_inds_y = [1, 3, n_cb]
    xticks_label = [
        i in label_inds_x ? string(vec_estimate) : "" for
        (i, vec_estimate) in enumerate(xticks)
    ]
    yticks_label = [
        i in label_inds_y ? string(vec_uncert) : "" for
        (i, vec_uncert) in enumerate(yticks)
    ]

    ax = Axis(
        gl[1, 2],
        aspect = DataAspect(),
        xlabel = "Voltage [µV]", ylabel = uncert_label, title = "",
        xlabelsize = 16, ylabelsize = 16,
        xticklabelsize = 12,
        yticklabelsize = 12,
        ylabelpadding = 0,
        xticks = (collect(1:n_cb), xticks_label),
        yticks = (collect(1:n_cb), yticks_label),
        width = 130, height = 130
    )

    heatmap!(ax, (colorbox'); colormap = vec(colorbox))
    hidedecorations!(ax, label = false, ticks = false, ticklabels = false)
    hidespines!(ax)

    topo_axis = Axis(
        gl[1, 1],
        aspect = DataAspect(),
        xlabel = "",
        width = 300, height = 300,
        limits = (-1.25, 1.25, -1.25, 1.2),
    )

    set_topoplot_bivariate!(;
        colorbox     = colorbox,
        norm_method  = :robust_minmax,
        norm_qrange  = (0.005, 0.995),
        norm_flip_v  = false,
        sample_mode  = :nearest,
    )
    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                (;)

    TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        topo_args...,
        contours = true,
    )
    hidedecorations!(topo_axis, label = false); hidespines!(topo_axis)
    colgap!(gl, 5)
    return gl
end


function plot_bivariate_corner(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_bivariate_corner!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

plot_bivariate_corner(test.estimate, test.se; labels = test.labels, uncert_label = "SE")

begin
    f = Figure(size = (500, 300), #figure_padding = (0, 0, -20, 10)
    )
    plot_bivariate_corner!(f, test.estimate, test.se; labels = test.labels, uncert_label = "SE")
    f
end

function plot_bivariate_range!(
    f::Union{GridPosition, GridLayout, Figure},
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    n_cb=5,
    uncert_label="Uncertainty",
    order_vertical = :low_to_high,
    enable_contour=true,
)
    gl = f isa Figure ? f.layout :
         f isa GridLayout ? f :
         (f[] = GridLayout())

    colorbox = bivariate_colormatrix_range(
        n_rows = n_cb,
        n_cols = n_cb,
        neg = colorant"#2166ac",
        mid = colorant"#FFFFBF",
        pos = colorant"#f46d43",
        order_vertical = order_vertical,
    )

    xticks = round.(
        collect(range(UnfoldMakie._topo_range_from_values(vec_estimate)...; length=n_cb)),
        digits=2,
    )
    yticks = round.(collect(range(extrema(vec_uncert)...; length=n_cb)), digits=2)

    label_inds_x = [1, 3, n_cb]
    label_inds_y = [1, 3, n_cb]

    xticks_label = [i in label_inds_x ? string(x) : "" for (i, x) in enumerate(xticks)]
    yticks_label = [i in label_inds_y ? string(y) : "" for (i, y) in enumerate(yticks)]

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    topo_axis = Axis(
        gl[1, 1],
        aspect = DataAspect(),
        xlabel = "",
        width = 300, height = 300,
        limits = (-1.25, 1.25, -1.25, 1.2),
    )

    set_topoplot_bivariate!(;
        colorbox    = colorbox,
        norm_method = :robust_minmax,
        norm_qrange = (0.005, 0.995),
        norm_flip_v = false,
        sample_mode = :nearest,
        contours = (; lab_bins = (16,16,16), linestyle = :dot)
    )

    TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        topo_args...,
        contours = enable_contour,
    )

    hide_axis!(topo_axis)

    ax = Axis(
        gl[1, 2],
        aspect = DataAspect(),
        xlabel = "Voltage [µV]",
        ylabel = uncert_label,
        title = "",
        xlabelsize = 16, ylabelsize = 16,
        xticklabelsize = 12,
        yticklabelsize = 12,
        ylabelpadding = 0,
        xticks = (collect(1:n_cb), xticks_label),
        yticks = (collect(1:n_cb), yticks_label),
        width = 130, height = 130
    )

    heatmap!(ax, colorbox'; colormap = vec(colorbox))
    hidedecorations!(ax, label=false, ticks=false, ticklabels=false)
    hidespines!(ax)
    colgap!(gl, 5)
    return gl
end

function plot_bivariate_range(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_bivariate_range!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

plot_bivariate_range(test.estimate .- 4.55, test.se; labels = test.labels, uncert_label = "SE")



function plot_vsp!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "Uncertainty",
    enable_contour = true,
    reverse_vsp_rows = true,
    colormap_vsp = :RdYlBu,
)
    gl = f isa Figure ? f.layout :
         f isa GridLayout ? f :
         (f[] = GridLayout())
    vec_estimate_c = UnfoldMakie._topo_range_from_values(vec_estimate)

    uncert_labels = string.(round.(collect(range(extrema(vec_uncert)...; length = 5)), digits = 2))
    value_labels = reverse(string.(
        Any[
            round(minimum(vec_estimate_c), digits = 2),
            Int(round(mean(vec_estimate_c))),
            round(maximum(vec_estimate_c), digits = 2),
        ]
    ))
     
    vsp_axis = PolarAxis(
        gl[2:3, 3:4];
        width = 200, height = 170,
        thetalimits = (-π / 5, π / 5),
        theta_0 = π / 2, thetaticklabelsize = 12, rticklabelsize = 12,
        halign = :right,# clipcolor = :green
    )
    
    vsup_cmap = vsup_colormatrix(;
        cmap = cgrad(colormap_vsp; rev = true), n_uncertainty = 4,
        max_desat = 0.8, pow_desat = 1.0, max_light = 0.7, pow_light = 1,
    )

    vsp_rows = reverse([(vsup_cmap'[:, i]) for i = 1:size(vsup_cmap', 2)])

    norm_flip_v = true
    if !reverse_vsp_rows
        uncert_labels = reverse(uncert_labels)
        norm_flip_v = false
    end

    vsp_polar_legend!(
        vsp_axis;
        vsp_rows = vsp_rows,
        value_labels = value_labels, uncert_labels = uncert_labels,
        thetalims = (-π / 5, π / 5), theta0 = π / 2,
    )
    topo_axis = Axis(
        gl[1:4, 1:2]; aspect = DataAspect(),
        xlabel = "", width = 300, height = 300,
        limits = (-1.25, 1.25, -1.25, 1.2),
    )
    hidedecorations!(topo_axis, label = false); hidespines!(topo_axis)

    set_topoplot_bivariate!(;
        colorbox    = vsp_rows_to_colorbox(vsp_rows),
        norm_method = :robust_minmax,
        norm_qrange = (0.005, 0.995),
        norm_flip_v = norm_flip_v,
        sample_mode = :nearest,
    )

    topo_args =
        positions !== nothing ? (; positions = positions) :
        labels !== nothing    ? (; labels = labels) :
                                error("Either positions or labels must be provided.")

    TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        topo_args...,
        contours = enable_contour,
    )


    lx = Label(gl[2:3, 3:4], "Voltage [µV]", tellwidth = false, padding = (100, 0, 160, 0))
    ly = Label(gl[2:3, 3:4], uncert_label, tellheight = false, rotation = pi/3, padding = (0, -210, -80, 0))
    translate!(lx.blockscene, 0, 0, 10_000)
    translate!(ly.blockscene, 0, 0, 10_000)
    translate!(topo_axis.blockscene, 0, 0, 10_000)
    colgap!(gl, -100)
    return gl
end

begin
    f = Figure(size = (500, 300), figure_padding = (16, -10, 16, 10))
    plot_vsp!(f, test.estimate, test.se; labels = test.labels, uncert_label = "|t|-value")
    f
end

function plot_vsp(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_vsp!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end


plot_vsp(test.estimate .- 4.55, test.t; labels = test.labels, uncert_label = "|t|-value")

function plot_uncert_markers!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "Uncertainty",
    enable_contour = true,
)
    gl = f isa GridLayout ? f : f isa Figure ? (f[1, 1] = GridLayout()) : (f[] = GridLayout())

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    uncert_scaled = uncert_norm .* 30 .+ 10

    plot_topoplot!(
        gl[1:3, 1],
        vec_estimate;
        topo_args...,
        axis = (; xlabel = "", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (;
                markersize = uncert_scaled,
                color = :transparent,
                strokecolor = :black,
                strokewidth = uncert_scaled .* 0.25,   
            ),
        ),
        topo_axis = (; #backgroundcolor = :pink, 
        limits = (-1.25, 1.25, -1.3, 1.15),
        ),
        visual = (;
            colormap = cgrad(:RdYlBu, 10; categorical=true, rev=true),
            contours = enable_contour,
        ),
        colorbar = (; labelsize = 24, ticklabelsize = 18, height = 220),
    )

    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))
    markerlabels = round.(range(extrema(vec_uncert)...; length = 5); digits = 2)

    group_size = [
        MarkerElement(
            marker = :circle,
            color = :transparent,
            strokecolor = :black,
            strokewidth = ms ÷ 5,
            markersize = ms,
        )
        for ms in markersizes
    ]

    Legend(
        gl[4, 1],
        group_size,
        ["$x" for x in markerlabels],
        uncert_label,
        patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8),
        framevisible = false,
        labelsize = 18,
        titlesize = 20,
        orientation = :horizontal,
        titleposition = :left,
        colgap = 5,
        margin = (90, 10, -8, 0),
    )
    rowsize!(gl, 1, Relative(0.35))
    rowsize!(gl, 2, Relative(0.3))
    rowsize!(gl, 3, Relative(0.3))
    rowsize!(gl, 4, Auto(0.15))
    rowgap!(gl, -10)
    return gl
end

function plot_uncert_markers(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_uncert_markers!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

plot_uncert_markers(test.estimate .- 4.55, test.abs_t; labels = test.labels, uncert_label = "|t|-value")

begin
    f = Figure(size = (500, 300))
    plot_uncert_markers!(f, test.estimate .- 4.55, test.abs_t; labels = test.labels, uncert_label = "|t|-value")
    f
end

function plot_triple_CI!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "SE",
    BG = :white,
)
    gl = f isa GridLayout ? f : f isa Figure ? (f[1, 1] = GridLayout()) : (f[] = GridLayout())

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    pTopos = GridLayout()
    gl[1:2, 1:3] = pTopos

    pA  = pTopos[1, 2]
    pB  = pTopos[2, 1]
    pC  = pTopos[2, 3]
    pcb = gl[:, 4]

    lims = begin
        allvals = vcat(
            vec_estimate,
            vec_estimate .- vec_uncert,
            vec_estimate .+ vec_uncert,
        )
        p01 = _percentile(0.01, allvals)
        p99 = _percentile(0.99, allvals)
        m = max(abs(p01), abs(p99))
        Float32.((-m, m))
    end

    visual = (;
        limits = lims,
        colormap = cgrad(:RdYlBu, 10; categorical=true, rev=true),
    )

    ticks5 = begin
        lo, hi = visual.limits
        pos = Float32[lo, lo/2, 0f0, hi/2, hi]
        lab = string.(round.(Float64.(pos); sigdigits=2))
        (pos, lab)
    end

    plot_topoplot!(
        pA,
        vec_estimate;
        topo_args...,
        axis = (; backgroundcolor=BG, ylabelsize=16, ylabel="", xlabel=""),
        topo_axis = (; backgroundcolor=BG),
        layout = (; use_colorbar=false),
        visual = visual,
    )

    plot_topoplot!(
        pB,
        vec_estimate .- vec_uncert;
        topo_args...,
        axis = (; backgroundcolor=BG, xlabelsize=16, xlabel="Mean - $uncert_label"),
        topo_axis = (; backgroundcolor=BG),
        visual = visual,
        layout = (; use_colorbar=false),
    )

    plot_topoplot!(
        pC,
        vec_estimate .+ vec_uncert;
        topo_args...,
        topo_axis = (; backgroundcolor=BG),
        axis = (; backgroundcolor=BG, xlabelsize=16, xlabel="Mean + $uncert_label"),
        visual = visual,
        layout = (; use_colorbar=false),
    )

    Colorbar(
        pcb,
        colormap = visual.colormap, limits = visual.limits,
        ticks = ticks5, label = "Voltage [µV]",
        labelsize = 24,
        ticklabelsize = 12,
        vertical = true,
        height = 240,
        flipaxis = true,
        labelrotation = -π/2,
    )

    rowgap!(pTopos, -50)
    colgap!(pTopos, -90)
    rowgap!(gl, 0)

    return gl
end

begin
    f = Figure(size = (500, 300), figure_padding = (16, 16, 16, 10))
    plot_triple_CI!(f, test.estimate, test.se; labels = test.labels, uncert_label = "SE")
    f
end

function plot_triple_CI(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_triple_CI!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

plot_triple_CI(test.estimate .- 4.55, test.se; labels = test.labels, uncert_label = "SE")


function plot_HOP(
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    n_boot=20,
    rng=MersenneTwister(1),
    BG=RGBf(0.98, 0.98, 0.98),
    uncert_label = "SE",
)
    boot_means = hcat([
        vec_estimate .+ vec_uncert .* randn(rng, length(vec_estimate))
        for _ in 1:n_boot
    ]...)

    obs = Observable(boot_means[:, 1])

    vals = vec(boot_means)
    p01, p99 = quantile(vals, [0.01, 0.99])
    m = max(abs(p01), abs(p99))
    cr = Float32.((-m, m))

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    f = Figure(backgroundcolor=BG)

    plot_topoplot!(
        f,
        obs;
        topo_args...,
        topo_axis = (; backgroundcolor=BG),
        visual = (; contours=true, colormap=cgrad(:RdYlBu, 10; categorical=true, rev = true), colorrange=cr),
        colorbar = (; labelsize=24, ticklabelsize=18, height=300),
        axis = (; backgroundcolor=BG, xlabel="$uncert_label", xlabelsize=24, ylabelsize=24),
    )

    return f, obs, boot_means
end

f, obs, boot_means = plot_HOP(test.estimate, test.se; labels = test.labels, uncert_label = "SE")

function ease_between(old, new, update_ratio; easing_function = sineio())
    anim = Animation(0, old, 1, new; defaulteasing = easing_function)
    return at(anim, update_ratio)
end

function create_HOP_gif(f, obs, boot_means; filepath = "anim.gif")
    n_boot = 10
    record(f, filepath; framerate = 12) do io
        recordframe!(io)  # first frame (original)
        for i_boot = 1:(n_boot-1)          # number of bootstrap targets
            new_v = boot_means[:, i_boot+1]
            old_v = copy(obs[])
            for u in range(0, 1, length = 10)   # easing steps
                obs[] = ease_between(old_v, new_v, u)
                recordframe!(io)
            end
        end
    end
end

create_HOP_gif(f, obs, boot_means)


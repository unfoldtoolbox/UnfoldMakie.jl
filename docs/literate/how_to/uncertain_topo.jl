# # Visualize uncertainty in topoplots

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
using Base: channeled_tasks
using Unfold
using UnfoldMakie
using UnfoldSim
using DataFrames
using CairoMakie
using TopoPlots
using Statistics
using Random
using Animations

# ```@raw html
# </details >
# ```
# Representing uncertainty is one of the most difficult tasks in visualization. It is especially difficult for heatmaps and topoplots. 
# Here we will present new ways to show uncertainty for topoplots.

# Uncertainty in EEG data usually comes from subjects and trials: 
# 1) Subjects can vary in phisological or behavioral characteristics; 
# 2) Something can change between trials (electrode connection can get worse, etc.).

# There are several measures of uncertainty. Here we will use `standard deviation` (x - mean(x) / N) and `t-values` (mean(x) / SE(x)).
# # Data input
# Data for customized topoplots:
dat, positions = TopoPlots.example_data()
vec_estimate = dat[:, 340, 1];
vec_uncert = dat[:, 340, 2];
rng = MersenneTwister(1);

# # Adjacent topoplot
# In this case we already have two data vectors: `vec_estimate` with mean estimates and `vec_uncert` with standard deviation.

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function adjacent()
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
# ```@raw html
# </details >
# ```
adjacent()

# # Uncertainty via marker size
# We show uncertainty using donut-shaped electrode markers.
# The donut keeps the estimate color visible while the marker size reflects uncertainty — larger donuts mean higher uncertainty.
# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function marker_size_uncertainty()
    f = Figure()
    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    uncert_scaled = uncert_norm * 30 .+ 10

    plot_topoplot!(
        f[1:4, 1],
        vec_estimate;
        positions,
        axis = (; xlabel = "Time point [340 ms]", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (; markersize = uncert_scaled, color = :transparent,
                strokecolor = :black,
                strokewidth = uncert_scaled .* 0.25)
        ),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )
    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))

    group_size = [
        MarkerElement(
            marker = :circle,
            color = :transparent, strokecolor = :black, strokewidth = ms ÷ 5,
            markersize = ms) for ms in markersizes
    ]
    Legend(f[5, 1], group_size, ["$ms" for ms in markersizes], "Standard\ndeviation",
        patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8),
        framevisible = false,
        labelsize = 18, titlesize = 20,
        orientation = :horizontal, titleposition = :left, margin = (90, 0, 0, 0))
    f
end
# ```@raw html
# </details >
# ```
marker_size_uncertainty()

# # Uncertainty via bivariate colormap 
# Here we use a bivariate colormap to represent both estimate and uncertainty in a single topoplot.
# There are two types of such colormaps: 1) corner; 2) range.
# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function bivariate_corners()
    n_cb = 5
    colorbox = bivariate_colormatrix_corners(
        n_cb, n_cb;
        top_left = colorant"#564f9d",
        top_right = colorant"#ec7429",
        bot_right = colorant"#e50a7d",
        bot_left = colorant"#108644",
        mid = colorant"#e5e1e4",          # neutral center for the horizontal diverging
        order_vertical = :low_to_high,     # top→bottom gets “stronger”
    )

    f = Figure()
    xticks = round.(collect(range(extrema(vec_estimate)...; length = n_cb)), digits = 2)
    yticks = (round.(collect(range(extrema(vec_uncert)...; length = n_cb)), digits = 2))

    label_inds_x = [1, n_cb, length(xticks)]   # indices to keep labels
    label_inds_y = [1, n_cb, length(xticks)]   # indices to keep labels
    xticks_label = [
        i in label_inds_x ? string(vec_estimate) : "" for
        (i, vec_estimate) in enumerate(xticks)
    ]
    yticks_label = [
        i in label_inds_y ? string(vec_uncert) : "" for
        (i, vec_uncert) in enumerate(yticks)
    ]

    ax = Axis(f[1, 2], aspect = DataAspect(),
        xlabel = "Voltage [µV]", ylabel = "Standard deviation", title = "",
        xlabelsize = 24, ylabelsize = 24, titlesize = 24, titlealign = :center,
        xticklabelsize = 18,
        yticklabelsize = 18,
        xticks = (collect(1:n_cb), xticks_label),
        yticks = (collect(1:n_cb), yticks_label),
        width = 140, height = 140)

    heatmap!(ax, (colorbox'); colormap = vec(colorbox))
    hidedecorations!(ax, label = false, ticks = false, ticklabels = false)
    hidespines!(ax)

    topo_axis = Axis(
        f[1, 1],
        aspect = DataAspect(),
        xlabel = "Time window [340 ms]",
        xlabelsize = 24,
        width = 250,
        height = 250,
    )

    TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        positions = positions,
        colormap = colorbox,
        bivariate = (;
            norm_method = :robust_minmax,
            norm_qrange = (0.005, 0.995),
            norm_flip_v = false,
            sample_mode = :nearest,
        ),
    )
    hidedecorations!(topo_axis, label = false)
    hidespines!(topo_axis)
    f
end
# ```@raw html
# </details >
# ```
bivariate_corners()

# # Uncertainty via bivariate colormap (range type)
# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function bivariate_range()
    n_cb = 5
    colorbox = bivariate_colormatrix_range(
        n_rows = n_cb,
        n_cols = n_cb,
        neg = colorant"#2166ac",
        mid = colorant"#FFFFBF",
        pos = colorant"#f46d43",
        order_uncertainty = :low_to_high,
    )

    f = Figure()
    xticks = round.(collect(range(extrema(vec_estimate)...; length = n_cb)), digits = 2)
    yticks = (round.(collect(range(extrema(vec_uncert)...; length = n_cb)), digits = 2))

    label_inds_x = [1, n_cb, length(xticks)]
    label_inds_y = [1, n_cb, length(xticks)]
    xticks_label = [
        i in label_inds_x ? string(vec_estimate) : "" for
        (i, vec_estimate) in enumerate(xticks)
    ]
    yticks_label = [
        i in label_inds_y ? string(vec_uncert) : "" for
        (i, vec_uncert) in enumerate(yticks)
    ]

    ax = Axis(f[1, 2], aspect = DataAspect(),
        xlabel = "Voltage [µV]", ylabel = "Standard deviation", title = "",
        xlabelsize = 24, ylabelsize = 24, titlesize = 24, titlealign = :center,
        xticklabelsize = 18,
        yticklabelsize = 18,
        xticks = (collect(1:n_cb), xticks_label),
        yticks = (collect(1:n_cb), yticks_label),
        width = 140, height = 140)

    heatmap!(ax, (colorbox'); colormap = vec(colorbox))
    hidedecorations!(ax, label = false, ticks = false, ticklabels = false)
    hidespines!(ax)

    topo_axis = Axis(
        f[1, 1],
        aspect = DataAspect(),
        xlabel = "Time window [340 ms]",
        xlabelsize = 24,
        width = 250,
        height = 250,
    )

    TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        positions = positions,
        colormap = colorbox,
        bivariate = (;
            norm_method = :robust_minmax,
            norm_qrange = (0.005, 0.995),
            norm_flip_v = false,
            sample_mode = :nearest,
        ),
    )
    hidedecorations!(topo_axis, label = false)
    hidespines!(topo_axis)
    f
end
# ```@raw html
# </details >
# ```
bivariate_range()

# # Uncertainty via value-suppresing palette (VSP)
# Here we use a specialized colormap that suppresses colors for high-uncertainty areas while keeping colors vivid for low-uncertainty areas.

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function vsp_example()
    colormap_vsp = :berlin
    f = Figure(size = (550, 400))

    alphas_ticks = round.(collect(range(extrema(vec_uncert)...; length = 5)), digits = 2)
    value_labels = reverse(
        string.(
            round.(
                [minimum(vec_estimate), median(vec_estimate), maximum(vec_estimate)],
                digits = 2,
            )
        ),
    )
    uncert_labels = reverse(string.(alphas_ticks))  # outer→inner to match radial order

    vsp_axis = PolarAxis(f[1:4, 3:4]; width = 250, height = 220,
        thetalimits = (-π / 5, π / 5), theta_0 = π / 2,
        thetaticklabelsize = 20, rticklabelsize = 20)

    vsup_cmap = UnfoldMakie.vsup_colormatrix(;
        cmap = cgrad(colormap_vsp), n_uncertainty = 4,
        max_desat = 0.8, pow_desat = 1.0, max_light = 0.7, pow_light = 1,
    )

    vsp_rows = reverse([(vsup_cmap'[:, i]) for i = 1:size(vsup_cmap', 2)])

    UnfoldMakie.vsp_polar_legend!(vsp_axis;
        vsp_rows = vsp_rows,
        value_labels = value_labels,
        uncert_labels = uncert_labels,
        thetalims = (-π / 5, π / 5),
        theta0 = π / 2,
    )

     ax_dummy = Axis(f[1:4, 3:4],
        xlabel = xlabel = "Voltage [µV]",
        ylabel = ylabel = "Standard deviation",
        yaxisposition = :right,
        xaxisposition = :top,
        xlabelsize = 24, ylabelsize = 24,
        width = 230, height = 210,
    )
    hidedecorations!(ax_dummy, label = false); hidespines!(ax_dummy)

    topo_axis = Axis(f[1:4, 1:2], aspect = DataAspect(),
        xlabel = "Time window [340 ms]", xlabelsize = 24)
    hidedecorations!(topo_axis, label = false); hidespines!(topo_axis)

    TopoPlots.eeg_topoplot!(topo_axis, (vec_estimate, vec_uncert);
        positions = positions,
        colormap = UnfoldMakie.vsp_rows_to_colorbox(vsp_rows),
        labels = ["$(i)" for i = 1:64],
        contours = true,
        attributes = (;
            norm_method = :robust_minmax,
            norm_qrange = (0.005, 0.995),
            norm_flip_v = false,
            sample_mode = :nearest,
        ),
    )
    f
end
# ```@raw html
# </details >
# ```
vsp_example()
# # Uncertainty via animation 
# In this case, we need to boostrap the data, so we'll use raw data with single trials. 

# To show the uncertainty of the estimate, we will compute 10 different means of the boostrapped data. 
# More specifically: 1) create N boostrapped data sets using random sampling with replacement across trials; 2) compute their means; 3) do a toposeries animation iterating over these means. 

# ```@raw html
# <details>
# <summary>Click to expand for supportive functions</summary>
# ```
"""
param_bootstrap_means(mean_vec, se_vec; n_boot, rng)

Return (n_channels × n_boot) matrix of bootstrap mean vectors,
sampling independently per channel: μ + SE * randn().
"""
function param_bootstrap_means(mean_vec::AbstractVector, se_vec::AbstractVector;
    n_boot::Int = 10, rng = MersenneTwister(1))

    T = float(promote_type(eltype(mean_vec), eltype(se_vec)))
    μ = convert(Vector{T}, mean_vec)
    se = convert(Vector{T}, se_vec)
    n_channels = length(μ)

    out = Matrix{T}(undef, n_channels, n_boot)
    for i_boot = 1:n_boot
        out[:, i_boot] = μ .+ se .* randn(rng, T, n_channels)
    end
    return out
end

# function for easing - smooth transition between frames in animation.
# `update_ratio` - transition ratio between time1 and time2.
# `at` - create animation object: 0 and 1 are time points, old and new are data vectors.

function ease_between(old, new, update_ratio; easing_function = sineio())
    anim = Animation(0, old, 1, new; defaulteasing = easing_function)
    return at(anim, update_ratio)
end

# ```@raw html
# </details >
# ```

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
se_vec = vec_uncert ./ sqrt(15) # 15 subject according to paper
n_boot = 20
boot_means = param_bootstrap_means(vec_estimate, se_vec; n_boot = n_boot, rng = rng)

obs = Observable(boot_means[:, 1])
f = Figure()
plot_topoplot!(
    f[1, 1],
    obs;
    positions = positions,
    visual = (; contours = false),
    axis = (; xlabel = "Time [100 msec]"),
)

record(f, "bootstrap_single_topo.mp4"; framerate = 12) do io
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
# ```@raw html
# </details >
# ```

# ![](bootstrap_single_topo.mp4)

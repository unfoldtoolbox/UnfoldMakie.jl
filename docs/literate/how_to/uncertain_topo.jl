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
# ```@raw html
# </details >
# ```

# # Uncertainty via marker size
# We show uncertainty using donut-shaped electrode markers.
# The donut keeps the estimate color visible while the marker size reflects uncertainty — larger donuts mean higher uncertainty.
# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
begin
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

# ![](bootstrap_single_topo.mp4)

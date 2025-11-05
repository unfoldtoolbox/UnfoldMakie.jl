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
# Data for animation:

df_toposeries, pos_toposeries = UnfoldMakie.example_data("bootstrap_toposeries"; noiselevel = 7);
df_toposeries1 = df_toposeries[df_toposeries.trial.<=15, :];
rng = MersenneTwister(1);
# This will generate DataFrame with 227 channels, 50 trials, 500 mseconds for bootstrapping.
# `noiselevel` is important for adding variability it your data.

# # Adjacent topoplot
# In this case we already have two data vectors: `vec_estimate` with mean estimates and `vec_uncert` with standard deviation.

begin
    f = Figure()
    ax = Axis(f[1, 1:2], title = "Time windows [340 ms]", titlesize = 24, titlealign = :center,) 
    
    hidedecorations!(ax, label = false) ; hidespines!(ax)
    plot_topoplot!(
        f[1, 1],
        vec_estimate;
        positions = positions,
        visual = (; contours = false),
        axis = (; xlabel = ""),
        colorbar = (; label = "Voltage [µV]", labelsize = 24, ticklabelsize = 18, vertical = false, width = 180),
    )
    plot_topoplot!(
        f[1, 2],
        vec_uncert;
        positions = positions,
        visual = (; colormap = (:viridis), contours = false),
        axis = (; xlabel = "", xlabelsize = 24, ylabelsize = 24),
        colorbar = (; label = "Standard deviation", labelsize = 24, ticklabelsize = 18, vertical = false, width = 180),
    )
    f
end


# # Uncertainty via marker size
# We show uncertainty using donut-shaped electrode markers.
# The donut keeps the estimate color visible while the marker size reflects uncertainty — larger donuts mean higher uncertainty.
begin
    f = Figure()
    uncert_norm = (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert)) 
    uncert_scaled = uncert_norm * 30 .+ 10

    plot_topoplot!(
        f[1:4, 1],
        vec_estimate;
        positions,
        axis = (; xlabel = "Time point [340 ms]", xlabelsize = 24, ylabelsize = 24),
        topo_attributes = (;
            label_scatter = (; markersize = uncert_scaled, color = :transparent, strokecolor = :black,         
            strokewidth = uncert_scaled .* 0.25 )
        ),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18)
    )
    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))

    group_size = [MarkerElement(
        marker = :circle, 
        color = :transparent, strokecolor = :black, strokewidth = ms ÷ 5, 
        markersize = ms) for ms in markersizes]
    Legend(f[5, 1], group_size, ["$ms" for ms in markersizes], "Standard\ndeviation", 
        patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8), framevisible = false, 
        labelsize = 18, titlesize = 20,
        orientation = :horizontal, titleposition = :left, margin = (90,0,0,0))
    f
end

# # Uncertainty via arrow rotation
# In this case we will replace elctrode markers with arrows. The arrow direction will represent the level of uncertainty.
# Be aware: arrows are not representing any flow or direction of the signal. They are just a way to visualize uncertainty.
begin
    f = Figure()
    uncert_norm = (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert)) 
    rotations = -uncert_norm .* π # radians in [-2π, 0], negaitve - clockwise rotation

    arrow_symbols = ['↑', '↗', '→', '↘', '↓'] # 5 levels of uncertainty
    
    angles = range(extrema(vec_uncert)...; length=5) 
    labels = ["$(round(a, digits = 2))" for a in angles] # correspons to uncertainty levels

    plot_topoplot!(
        f[1:6, 1],
        vec_estimate;
        positions,
        topo_attributes = (;
            label_scatter = (;
                markersize = 20,
                marker = '↑',
                color = :gray, strokecolor = :black, strokewidth = 1,
                rotation = rotations,
            )
        ),
        axis = (; xlabel = "Time point [50 ms]", xlabelsize = 24, ylabelsize = 24),
        visual = (; colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18)
    )

    mgroup = [MarkerElement(marker = sym, color = :black, markersize = 20)
         for sym in arrow_symbols]

    Legend(f[7, 1], mgroup, labels, "Standard\ndeviation";
        patchlabelsize = 14, framevisible = false, 
        labelsize = 18, titlesize = 20,
        orientation = :horizontal, titleposition = :left, margin = (90,0,0,0),)
    f
end

# # Uncertainty via animation 

# In this case, we need to boostrap the data, so we'll use raw data with single trials. 

# To show the uncertainty of the estimate, we will compute 10 different means of the boostrapped data. 
# More specifically: 1) create N boostrapped data sets using random sampling with replacement across trials; 2) compute their means; 3) do a toposeries animation iterating over these means. 

# ```@raw html
# <details>
# <summary>Click to expand for supportive functions</summary>
# ```
# With this function we will bootstrap the data.
# `rng` - random number generated. Be sure to send the same rng from outside the function.
bootstrap_toposeries(df; kwargs...) = bootstrap_toposeries(MersenneTwister(), df; kwargs...)
function bootstrap_toposeries(rng::AbstractRNG, df)
    df1 = groupby(df, [:time, :channel])
    len_estimate = length(df1[1].estimate)
    bootstrap_ix = rand(rng, 1:len_estimate, len_estimate) # random sample with replacement
    tmp = vcat([d.estimate[bootstrap_ix] for d in df1]...)
    df1 = DataFrame(df1)

    df1.estimate .= tmp
    return df1
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

dat_obs = Observable(df_toposeries1)
f = Figure()
plot_topoplotseries!(
    f[1, 1],
    dat_obs;
    bin_num = 5,
    nrows = 2,
    positions = pos_toposeries,
    visual = (; contours = false),
    axis = (; xlabel = "Time [msec]"),
)

# Basic toposeries.

record(f, "bootstrap_toposeries_nocontours.mp4"; framerate = 2) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(rng, df_toposeries1)
        recordframe!(io)
    end
end;
# ![](bootstrap_toposeries_nocontours.mp4)

# Toposeries with easing.
# Easing means smooth transition between frames.
dat_obs = Observable(bootstrap_toposeries(rng, df_toposeries1))
f = Figure()
plot_topoplotseries!(
    f[1, 1],
    dat_obs;
    bin_num = 5,
    nrows = 2,
    positions = pos_toposeries,
    visual = (; contours = false),
    axis = (; xlabel = "Time [msec]"),
)
record(f, "bootstrap_toposeries_easing.mp4"; framerate = 10) do io
    for n_bootstrapping = 1:10
        recordframe!(io)
        new_df = bootstrap_toposeries(rng, df_toposeries1)
        old_estimate = deepcopy(dat_obs.val.estimate)
        for update_ratio in range(0, 1, length = 8)

            dat_obs.val.estimate .=
                ease_between(old_estimate, new_df.estimate, update_ratio)
            notify(dat_obs)
            recordframe!(io)
        end
    end
end;

# ![](bootstrap_toposeries_easing.mp4)

# # Static version of animation 
function draw_topoplots(rng, df_toposeries1)
    fig = Figure(size = (800, 600))

    merged_df = DataFrame()
    for i = 1:2, j = 1:3
        boo = bootstrap_toposeries(rng, df_toposeries1)
        boo.condition .= string((i - 1) * 3 + j) # Assign condition number
        merged_df = vcat(merged_df, boo)

    end
    plot_topoplotseries!(
        fig,
        merged_df;
        nrows = 2,
        mapping = (; col = :condition),
        axis = (; titlesize = 20, title = "Bootstrapped means", xlabel = ""),
        positions = pos_toposeries,
    )
    fig
end

draw_topoplots(rng, df_toposeries1)

# # Single topoplot with easing animation

# ```@raw html
# <details>
# <summary>Click to expand for supportive functions</summary>
# ```
sd_vec(vec_uncert; n_trials) = vec_uncert .* sqrt(n_trials)
"""
param_bootstrap_means(mean_vec, se_vec; n_boot, rng)

Return (n_channels × n_boot) matrix of bootstrap mean vectors,
sampling independently per channel: μ + SE * randn().
"""
function param_bootstrap_means(mean_vec::AbstractVector, se_vec::AbstractVector;
        n_boot::Int=10, rng=MersenneTwister(1))

    T = float(promote_type(eltype(mean_vec), eltype(se_vec)))
    μ = convert(Vector{T}, mean_vec)
    se = convert(Vector{T}, se_vec)
    n_channels = length(μ)

    out = Matrix{T}(undef, n_channels, n_boot)
    for i_boot in 1:n_boot
        out[:, i_boot] = μ .+ se .* randn(rng, T, n_channels)
    end
    return out
end
# ```@raw html
# </details >
# ```

n_boot = 20
boot_means = param_bootstrap_means(vec_estimate, vec_uncert; n_boot = n_boot, rng=rng)

obs = Observable(boot_means[:, 1])
f = Figure()
plot_topoplot!(
    f[1, 1],
    obs;
    positions = positions,
    visual = (; contours = false),
    axis = (; xlabel = "Time [100 msec]"),
)
f

record(f, "bootstrap_single_topo.mp4"; framerate = 12) do io
    recordframe!(io)  # first frame (original)
    for i_boot in 1:(n_boot - 1)          # number of bootstrap targets
        new_v = boot_means[:, i_boot + 1]
        old_v = copy(obs[])
        for u in range(0, 1, length=10)   # easing steps
            obs[] = ease_between(old_v, new_v, u)
            recordframe!(io)
        end
    end
end

# ![](bootstrap_single_topo.mp4)



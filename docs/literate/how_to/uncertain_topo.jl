using Base: channeled_tasks
# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
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
# Here we will present new ways to show uncertainty for topoplots series.

# Uncertainty in EEG data usually comes from subjects and trials: 
# 1) Subjects can vary in phisological or behavioral characteristics; 
# 2) Something can change between trials (electrode connection can get worse, etc.).

# Data input
dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)));
df_uncert = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 2], string.(1:length(positions)));

# Generate data with 227 channels, 50 trials, 500 mseconds for bootstrapping
# noiselevel is important for adding variability it your data
df_toposeries, pos_toposeries =
    UnfoldMakie.example_data("bootstrap_toposeries"; noiselevel = 7);
df_toposeries = df_toposeries[df_toposeries.trial.<=15, :];
rng = MersenneTwister(1)

# # Uncertainty via additional row
# In this case we alread have two datasets: `df` with mean estimates and `df_uncert` with variability estimation.

f = Figure()
plot_topoplotseries!(
    f[1, 1],
    df;
    bin_num = 5,
    positions = positions,
    axis = (; xlabel = ""),
    colorbar = (; label = "Voltage estimate"),
)
plot_topoplotseries!(
    f[2, 1],
    df_uncert;
    bin_num = 5,
    positions = positions,
    visual = (; colormap = :viridis),
    axis = (; xlabel = "50 ms"),
    colorbar = (; label = "Voltage uncertainty"),
)
f
# # Markers for uncertainty

df_uncert_chan = groupby(df_uncert[df_uncert.time.==50, :], [:channel])
df_uncert_chan = combine(df_uncert_chan, :estimate => mean => :estimate)
plot_topoplot(
    dat[:, 50, 1];
    positions,
    axis = (; xlabel = "50 ms"),
    topo_attributes = (;
        label_scatter = (;
            markersize = df_uncert.estimate * 300,
            marker = :circle,
            color = :white,
            strokecolor = :tomato,
        )
    ),
)

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

dat_obs = Observable(df_toposeries)
f = Figure()
plot_topoplotseries!(
    f[1, 1],
    dat_obs;
    bin_num = 5,
    nrows = 2,
    positions = pos_toposeries,
    axis = (; xlabel = "Time [msec]"),
)

# Basic toposeries
record(f, "bootstrap_toposeries.mp4"; framerate = 2) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(rng, df_toposeries)
        recordframe!(io)
    end
end;
# ![](bootstrap_toposeries.mp4)

# Toposeries without contour
dat_obs = Observable(df_toposeries)
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
record(f, "bootstrap_toposeries_nocontours.mp4"; framerate = 2) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(rng, df_toposeries)
        recordframe!(io)
    end
end;
# ![](bootstrap_toposeries_nocontours.mp4)

# Toposeries with easing (smooth transition between frames)
dat_obs = Observable(bootstrap_toposeries(rng, df_toposeries))
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
        new_df = bootstrap_toposeries(rng, df_toposeries)
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
function draw_topoplots(rng, df_toposeries)
    fig = Figure(size = (800, 600))

    merged_df = DataFrame()
    for i = 1:2, j = 1:3
        boo = bootstrap_toposeries(rng, df_toposeries)
        boo.condition .= string((i - 1) * 3 + j) # Assign condition number
        merged_df = vcat(merged_df, boo)

    end
    plot_topoplotseries!(fig, merged_df; nrows = 2,
        mapping = (; col = :condition),
        axis = (; titlesize = 20, title = "Bootstrapped means", xlabel = ""),
        positions = pos_toposeries,
    )
    fig
end

draw_topoplots(rng, df_toposeries)

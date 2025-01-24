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
# 1) Subjects may vary by phsiological or behavioral features; 
# 2) Something can change between trials (electrode connection can got worse etc.).

# Data input
include("../../../example_data.jl")
dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)));
df_uncert = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 2], string.(1:length(positions)));

# Generate data with 227 channels, 50 trials, 500 mseconds for bootstrapping
df_toposeries, pos_toposeries = example_data("bootstrap_toposeries");
df_toposeries = df_toposeries[df_toposeries.trial.<=15, :]


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

# # Uncertainty via animation 

# In this case we need to do boostrapping of the data and that's why use raw data with individual trials. 

# To show uncertainty of estimate we will compute 10 different means of bootsrtaped data. 
# More detailed: 1) create N boostrapped datasets by random sampling with replacement across trials; 2) compute their means; 3) do toposeries animation iterating across these means. 

# ```@raw html
# <details>
# <summary>Click to expand for supportive functions</summary>
# ```
# This function we need to bootsrtap data.
bootstrap_toposeries(df; kwargs...) = bootstrap_toposeries(MersenneTwister(), df; kwargs...)
function bootstrap_toposeries(rng::AbstractRNG, df)
    # rng - random number generated. Be usre to send the same rng from outside
    df1 = groupby(df, [:time, :channel])
    len_estimate = length(df1[1].estimate)
    bootstrap_ix = rand(rng, 1:len_estimate, len_estimate) # random sample with rreplacemnt
    tmp = vcat([d.estimate[bootstrap_ix] for d in df1]...)
    df1 = DataFrame(df1)

    df1.estimate .= tmp
    return df1
end

function ease_between(new, old, update_ratio; easing_function = sineio())
    # function for easing - smoooth transition between frames in animation
    # update_ratio - stage of transion between time1 and time2
    anim = Animation(0, old, 1, new; defaulteasing = easing_function)
    # create animation Object: 0 and 1 are time points, old and new are data vectors 
    return at(anim, update_ratio)
end
# ```@raw html
# </details >
# ```

# Toposeries with easing (smooth transition between frames)
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
record(f, "bootstrap_toposeries_easing.mp4"; framerate = 10) do io
    rng = MersenneTwister(1)
    for n_bootstrapping = 1:10
        recordframe!(io)
        new_df = bootstrap_toposeries(rng, df_toposeries)
        old_estimate = dat_obs.val.estimate
        for update_ratio in range(0, 1, length = 8)
            #@show n_bootstrapping update_ratio
            dat_obs.val.estimate .=
                ease_between(new_df.estimate, old_estimate, update_ratio)
            notify(dat_obs)
            recordframe!(io)
        end
    end
end;

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
        dat_obs[] = bootstrap_toposeries(df_toposeries)
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
        dat_obs[] = bootstrap_toposeries(df_toposeries)
        recordframe!(io)
    end
end;
# ![](bootstrap_toposeries_nocontours.mp4)


# ![](bootstrap_toposeries_easing.mp4)

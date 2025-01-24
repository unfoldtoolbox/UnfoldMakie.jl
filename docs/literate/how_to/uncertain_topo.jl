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

# Data input
include("../../../example_data.jl")
dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)));
df_uncert = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 2], string.(1:length(positions)));

# Generate data with 227 channels, 50 trials, 500 mseconds for bootstrapping
df_toposeries, pos_toposeries = data, pos = example_data("bootstrap_toposeries");
nothing #hide

# # Uncertainty via additional row

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

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
# This function we need to bootsrtap data.
function bootstrap_toposeries(df)
    df1 = groupby(df, [:time, :channel])
    tmp = vcat([d.estimate[rand(1:length(d.estimate), length(d.estimate))] for d in df1]...)
    df1 = DataFrame(df1)
    df1.estimate = tmp
    return df1
end
# ```@raw html
# </details >
# ```

#  To show uncertainty of estimate we will compute 10 different means of bootstrapped data. 
# More detailed: 1) create N boostrapped datasets by random sampling with replacement across trials; 2) compute their means; 3) do toposeries animation iterating across these means. 
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
record(f, "bootstrap_toposeries.mp4"; framerate = 2) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(df_toposeries)
        recordframe!(io)
    end
end;
# ![](bootstrap_toposeries.mp4)

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
f
record(f, "bootstrap_toposeries_nocontours.mp4"; framerate = 2) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(df_toposeries)
        recordframe!(io)
    end
end;
# ![](bootstrap_toposeries_nocontours.mp4)

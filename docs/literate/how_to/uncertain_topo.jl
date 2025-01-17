using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using Statistics
using UnfoldSim
using Random

# Data input

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)));
df_uncert = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 2], string.(1:length(positions)));
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

function bootstrap_toposeries(df)
    df1 = groupby(df, [:time, :channel])
    tmp = vcat([d.estimate[rand(1:64, 64)] for d in df1]...)
    df1 = DataFrame(df1)
    df1.estimate = tmp
    return df1
end

dat_obs = Observable(df)
f = Figure()
plot_topoplotseries!(f[1, 1], dat_obs; bin_num = 5, nrows = 2, positions = positions)
record(f, "bootstrap_toposeries.gif"; framerate = 10000) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(df)
        recordframe!(io)
    end
end

# ![](bootstrap_toposeries.gif)


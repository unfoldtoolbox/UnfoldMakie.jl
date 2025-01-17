using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using TopoPlots
using Statistics

# Data input

data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(data[:, :, 1], string.(1:length(positions)));
nothing #hide

# # Ucertainty via additional row

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


# # Toposeries: uncertainty via animation 

function bootstrap_toposeries(df)
    df1 = groupby(df, [:time])
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
f
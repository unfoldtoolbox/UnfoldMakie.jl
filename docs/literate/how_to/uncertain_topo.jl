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

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
## Load required packages
# This function we need to bootsrtap data.
function bootstrap_toposeries(df)
    df1 = groupby(df, [:time, :channel])
    tmp = vcat([d.estimate[rand(1:length(d.estimate), length(d.estimate))] for d in df1]...)
    df1 = DataFrame(df1)
    df1.estimate = tmp
    return df1
end

# Generate data with 227 channels, 50 trials, 500 mseconds
function generate_toposeriesdata(trials = 50, time_padding = 100, component = n400())
    design = SingleSubjectDesign(conditions = Dict(:condA => ["levelA"])) # design with one condition
    design = RepeatDesign(design, trials)
    generate_events(design)

    time1 = vcat(rand(time_padding), component) # 500 msec = randiom 100 msec and 400 msec of n400
    c = LinearModelComponent(; basis = time1, formula = @formula(0 ~ 1), β = [1])

    hart = headmodel(type = "hartmut") # 227 electrodes
    less_hart = magnitude(hart)[:, 1] # extract 1 lead field and 64 electrodes

    mc = UnfoldSim.MultichannelComponent(c, less_hart)

    # simulation of 3d matrix
    onset = UniformOnset(; width = 20, offset = 4)
    dat, events = simulate(
        MersenneTwister(1),
        design,
        mc,
        onset,
        PinkNoise(noiselevel = 0.05),
        return_epoched = true,
    )

    # Create the DataFrame
    df = DataFrame(
        :estimate => dat[:],
        :channel => repeat(1:size(dat, 1), outer = Int(length(dat[:]) / size(dat, 1))),
        :time => repeat(1:size(dat, 2), outer = Int(length(dat[:]) / size(dat, 2))),
        :trial => repeat(1:size(dat, 3), outer = Int(length(dat[:]) / size(dat, 3))),
    )

    # chosing positions
    pos3d = hart.electrodes["pos"]
    pos2d = to_positions(pos3d')
    pos2d = [Point2f(p[1] + 0.5, p[2] + 0.5) for p in pos2d]
    return df, pos2d
end
# ```@raw html
# </details >
# ```

#  To show uncertainty of estimate we will compute 10 different means of bootsrtaped data. 
# More detailed: 1) create N boostrapped datasets by random sampling with replacement across trials; 2) compute their means; 3) do toposeries animation iterating across these means. 
df_toposeries, pos_toposeries = generate_toposeriesdata()
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
record(f, "bootstrap_toposeries.gif"; framerate = 10000) do io
    for i = 1:10
        dat_obs[] = bootstrap_toposeries(df_toposeries)
        recordframe!(io)
    end
end

# ![](bootstrap_toposeries.gif)

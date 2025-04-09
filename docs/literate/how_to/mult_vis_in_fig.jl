# # [Include multiple Visualizations in one Figure](@id ht_mvf)

#=
This section discusses how users can incorporate multiple plots into a single figure.
=#

# # Setup
# ## Library load

using UnfoldMakie
using CairoMakie
using DataFramesMeta
using UnfoldSim
using Unfold
using MakieThemes
using TopoPlots


# ## Data input
d_topo, positions = UnfoldMakie.example_data("TopoPlots.jl")
uf_deconv = UnfoldMakie.example_data("UnfoldLinearModelContinuousTime")
uf = UnfoldMakie.example_data("UnfoldLinearModel")
results = coeftable(uf)
uf_5chan = UnfoldMakie.example_data("UnfoldLinearModelMultiChannel")
data, positions = TopoPlots.example_data()
dat_e, evts, times = UnfoldMakie.example_data("sort_data")
d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched = true)
nothing #hide

# # Basic complex figure

#=
By using the !-version of the plotting function and inserting a grid position instead of an entire figure, we can create complex plot combining several figures.
=#
# We will start by creating a figure with `Makie.Figure`.

# `f = Figure()`

# Now any plot can be added to `f` by placing a grid position, such as `f[1, 1]`.
# Also we used a specified theme `fresh`.

f = Figure()
with_theme(theme_ggthemr(:fresh)) do

    plot_erp!(f[1, 1], coeftable(uf_deconv))
    plot_erp!(
        f[1, 2],
        effects(Dict(:condition => ["car", "face"]), uf_deconv),
        mapping = (; color = :condition),
    )
    plot_butterfly!(f[2, 1:2], d_topo; positions = positions)
end
f

# # Very complex figure
#=
We can create a large figure with any type of plot using predefined data.

With so many plots at once, it's better to set a fixed resolution in your image to order the plots evenly.
=#

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
begin
    f = Figure(size = (2000, 2000))

    plot_butterfly!(f[1, 1:3], d_topo; positions = positions)

    pvals = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5], # if coefname not specified, line should be black
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(f[2, 1:2], results, significance = pvals, stderror = true)

    plot_designmatrix!(f[2, 3], designmatrix(uf))

    plot_topoplot!(f[3, 1], data[:, 150, 1]; positions = positions)
    plot_topoplotseries!(
        f[4, 1:3],
        d_topo;
        bin_width = 0.1,
        positions = positions,
        mapping = (; label = :channel),
    )

    res_effects = effects(Dict(:continuous => -5:0.5:5), uf_deconv)

    plot_erp!(
        f[2, 4:5],
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous => nonnumeric),
        legend = (; nbanks = 2),
    )

    plot_parallelcoordinates(f[3, 2:3], uf_5chan; mapping = (; color = :coefname))

    plot_erpimage!(f[1, 4:5], times, d_singletrial)
    plot_circular_topoplots!(
        f[3:4, 4:5],
        d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
        positions = positions,
        predictor = :time,
        predictor_bounds = [-0.3, 0.5],
    )
end
# ```@raw html
# </details >
# ```
f

# # Complex figure in two columns

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function complex_figure3()
    f = Figure(size = (1200, 1700))
    ga = f[1, 1]
    gc = f[2, 1]
    ge = f[3, 1]
    gg = f[4, 1]
    gi = f[5:6, 1]
    gb = f[1, 2]
    gd = f[2, 2]
    gf = f[3, 2]
    gh = f[4, 2]
    gj = f[5:6, 2]

    d_topo, pos = UnfoldMakie.example_data("TopoPlots.jl")
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_array_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    channels_30 = UnfoldMakie.example_montage("channels_30")

    m = UnfoldMakie.example_data("UnfoldLinearModel")
    results = coeftable(m)

    results.coefname =
        replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
    results = filter(row -> row.coefname != "continuous", results)

    plot_erp!(
        ga,
        results;
        :stderror => true,
        mapping = (; color = :coefname => "Conditions"),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]"),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    plot_butterfly!(
        gb,
        d_topo;
        positions = pos,
        topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]"),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    plot_topoplot!(
        gc,
        data[:, 340, 1];
        positions = positions,
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; xlabel = "[340 ms]"),
    )

    plot_topoplotseries!(
        gd,
        df;
        bin_width = 80,
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]"),
    )

    plot_erpgrid!(
        ge,
        data[:, :, 1],
        positions;
        indicator_grid_axis = (;
            ylabel = "µV",
            xlabel = "Time [ms]",
            ylim = [-0.05, 0.6],
            xlim = [-0.04, 1],
        ),
        axis = (; backgroundcolor = colorant"#F4F3EF",),
    )

    dat_e, evts, times = UnfoldMakie.example_data("sort_data")
    plot_erpimage!(
        gf,
        times,
        dat_e;
        sortvalues = evts.Δlatency,
        axis = (; xlabel = "Time [ms]"),
    )
    m1 = UnfoldMakie.example_data("UnfoldLinearModelwith1Spline")
    plot_splines!(gg, m1; spline_axis = (; backgroundcolor = colorant"#F4F3EF"), density_axis = (; backgroundcolor = colorant"#F4F3EF"))
    r1, positions = UnfoldMakie.example_data()
    r2 = deepcopy(r1)
    r2.coefname .= "B" # create a second category
    r2.estimate .+= rand(length(r2.estimate)) * 0.1
    results_plot = vcat(r1, r2)
    plot_parallelcoordinates(
        gh,
        subset(results_plot, :channel => x -> x .< 8, :time => x -> x .< 0);
        mapping = (; color = :coefname),
        normalize = :minmax,
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7"],
        axis = (; backgroundcolor = colorant"#F4F3EF", ylabel = "Time [ms]"),
    )
    df_circ = DataFrame(
        :estimate => eachcol(Float64.(data[:, 100:40:300, 1])),
        :circular_variable => [0, 50, 80, 120, 180, 210],
        :time => 100:40:300,
    )
    df_circ = flatten(df_circ, :estimate)
    plot_circular_topoplots!(
        gi,
        df_circ;
        positions = pos,
        center_label = "Time [s]",
        predictor = :time,
        topo_attributes = (; label_scatter = false,),
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; backgroundcolor = colorant"#F4F3EF"),
        predictor_bounds = [80, 320],
        colorbar = (; height = 180),
    )
    plot_channelimage!(
        gj,
        data[1:30, :, 1],
        positions[1:30],
        channels_30;
        axis = (; xlabel = "Time [ms]"),
    )

    for (label, layout) in
        zip(
        ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"],
        [ga, gb, gc, gd, ge, gf, gg, gh, gi, gj],
    )
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (20, 20, 22, 0),
            halign = :right,
        )
    end
    f
end
# ```@raw html
# </details >
# ```
with_theme(Theme(; backgroundcolor = colorant"#F4F3EF")) do
    complex_figure3()
end

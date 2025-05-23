d_topo, _ = UnfoldMakie.example_data("TopoPlots.jl")
data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(data[:, :, 1], string.(1:length(positions)))
results = coeftable(UnfoldMakie.example_data("UnfoldLinearModel"))

begin
    r1, positions = UnfoldMakie.example_data()
    r2 = deepcopy(r1)
    r2.coefname .= "B" # create a second category
    r2.estimate .+= rand(length(r2.estimate)) * 0.1
    results_plot = vcat(r1, r2)
end

@testset "8 plots" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1]
    gc = f[2, 1]
    ge = f[3, 1]
    gg = f[4, 1]
    gb = f[1, 2]
    gd = f[2, 2]
    gf = f[3, 2]
    gh = f[4, 2]

    plot_erp!(
        ga,
        results;
        :stderror => true,
        mapping = (; color = :coefname => "Conditions"),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    plot_butterfly!(
        gb,
        d_topo;
        positions,
        topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    plot_topoplot!(
        gc,
        data[:, 340, 1];
        positions,
        axis = (; xlabel = "[340 ms]"),
    )

    plot_topoplotseries!(
        gd,
        df;
        bin_width = 80,
        positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )

    ax = gd[1, 1] = Axis(f)
    text!(ax, 0, 0, text = "Time [ms]", align = (:center, :center), offset = (-20, -80))
    hidespines!(ax) # delete unnecessary spines (lines)
    hidedecorations!(ax, label = false)

    plot_erpgrid!(
        ge,
        data[:, :, 1],
        positions;
        indicator_grid_axis = (;
            text_x_kwargs = (; text = "s"),
            text_y_kwargs = (; text = "µV"),
        ),
    )

    dat_e, evts, times = UnfoldMakie.example_data("sort_data")
    plot_erpimage!(gf, times, dat_e; sortvalues = evts.Δlatency)
    plot_channelimage!(gg, data[1:30, :, 1], positions[1:30], channels_30;)

    plot_parallelcoordinates(
        gh,
        subset(results_plot, :channel => x -> x .< 8, :time => x -> x .< 0);
        mapping = (; color = :coefname),
        normalize = :minmax,
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7"],
    )

    for (label, layout) in
        zip(["A", "B", "C", "D", "E", "F", "G", "H"], [ga, gb, gc, gd, ge, gf, gg, gh])
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (20, 20, 22, 0), #(20, 70, 22, 0),
            halign = :right,
        )
    end
    f
    #save("dev/UnfoldMakie/docs/src/assets/complex_plot.png", f)
end


@testset "8 plots with a Figure" begin
    f = Figure(size = (1200, 1400))

    uf_5chan = UnfoldMakie.example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched = true)

    pvals = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5],
        # if coefname not specified, line should be black
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(f[1, 1], results, significance = pvals, stderror = true)

    plot_butterfly!(f[1, 2], d_topo; positions)
    plot_topoplot!(f[2, 1], data[:, 150, 1]; positions)
    plot_topoplotseries!(
        f[2, 2],
        d_topo;
        bin_width = 0.1,
        positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    plot_erpgrid!(f[3, 1], data[:, :, 1], positions)

    times = -0.099609375:0.001953125:1.0
    plot_erpimage!(f[3, 2], times, d_singletrial)

    plot_parallelcoordinates(f[4, 2], uf_5chan; mapping = (; color = :coefname))

    for (label, layout) in zip(
        ["A", "B", "C", "D", "E", "F", "G", "H"],
        [f[1, 1], f[1, 2], f[2, 1], f[2, 2], f[3, 1], f[3, 2], f[4, 1], f[4, 2]],
    )
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right,
        )
    end
    f
end


@testset "testing combined figure (a Figure from complex_plot from docs)" begin
    uf_deconv = UnfoldMakie.example_data("UnfoldLinearModelContinuousTime")
    uf_5chan = UnfoldMakie.example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched = true)
    times = -0.099609375:0.001953125:1.0

    f = Figure(size = (2000, 2000))

    plot_butterfly!(f[1, 1:3], d_topo; positions)

    pvals = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5],
        # if coefname not specified, line should be black
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(f[2, 1:2], results, significance = pvals, stderror = true)

    plot_designmatrix!(f[2, 3], designmatrix(uf))

    plot_topoplot!(f[3, 1], data[:, 150, 1]; positions)
    plot_topoplotseries!(
        f[4, 1:3],
        d_topo;
        bin_width = 0.1,
        positions,
        mapping = (; label = :channel),
    )

    res_effects = effects(Dict(:continuous => -5:0.5:5), uf_deconv)

    plot_erp!(
        f[2, 4:5],
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous => nonnumeric),
    )

    plot_parallelcoordinates(f[3, 2:3], uf_5chan; mapping = (; color = :coefname))

    plot_erpimage!(f[1, 4:5], times, d_singletrial)
    plot_circular_topoplots!(
        f[3:4, 4:5],
        d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
        positions,
        predictor = :time,
        predictor_bounds = [-0.3, 0.5],
    )

    f
    #save("test.png", f)
end

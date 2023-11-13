@testset "8 plots" begin
    f = Figure(resolution=(1200, 1400))
    ga = f[1, 1] = GridLayout()
    gc = f[2, 1] = GridLayout()
    ge = f[3, 1] = GridLayout()
    gg = f[4, 1] = GridLayout()
    geh = f[1:4, 2] = GridLayout()
    gb = geh[1, 1] = GridLayout()
    gd = geh[2, 1] = GridLayout()
    gf = geh[3, 1] = GridLayout()
    gh = geh[4, 1] = GridLayout()

    include("../docs/example_data.jl")
    d_topo, pos = example_data("TopoPlots.jl")
    uf_deconv = example_data("UnfoldLinearModelContinuousTime")
    uf = example_data("UnfoldLinearModel")
    results = coeftable(uf)
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched=true)
    times = -0.099609375:0.001953125:1.0
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:,:,1], string.(1:length(positions)));

    data_erp, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
    data_erp = reshape(data_erp, (1, size(data_erp)...))
    form = @formula 0 ~ 1 + condition + continuous
    se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true);
    m = fit(
        UnfoldModel,
        Dict(Any => (form, range(0, step = 1 / 100, length = size(data_erp, 2)))),
        evts,
        data_erp,
        solver = se_solver,
    )
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m);

    plot_erp!(ga, results; :stderror=>true, legend=(; framevisible = false))
    plot_butterfly!(gb, d_topo; positions=pos, topomarkersize = 10, topoheigth = 0.4, topowidth = 0.4,)
    plot_topoplot!(gc, data[:,340,1]; positions = positions)
    plot_topoplotseries!(gd, df, 80; positions=positions, visual=(label_scatter=false,), 
        layout = (; useColorbar=true))
    plot_erpgrid!(ge, data[:, :, 1], positions)
    plot_erpimage!(gf, times, d_singletrial)
    plot_parallelcoordinates!(gh, uf_5chan, [1, 2, 3, 4, 5]; 
        mapping=(; color=:coefname), layout=(; legendPosition=:bottom), legend=(; tellwidth =false))

    for (label, layout) in zip(["A", "B", "C", "D", "E", "F", "G", "H"], [ga, gb, gc, gd, ge, gf, gg, gh])
        Label(layout[1, 1, TopLeft()], label,
            fontsize=26,
            font=:bold,
            padding=(0, 5, 5, 0),
            halign=:right)
    end
    f
end


@testset "8 plots with a Figure" begin
    f = Figure(resolution=(1200, 1400))

    include("../docs/example_data.jl")
    d_topo, positions = example_data("TopoPlots.jl")
    data, positions = TopoPlots.example_data()
    uf = example_data("UnfoldLinearModel")
    results = coeftable(uf)
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched=true)


    pvals = DataFrame(
        from=[0.1, 0.15],
        to=[0.2, 0.5],
        # if coefname not specified, line should be black
        coefname=["(Intercept)", "category: face"]
    )
     plot_erp!(f[1, 1], results, extra=(;
        categoricalColor=false,
        categoricalGroup=false,
        pvalue=pvals,
        stderror=true)) 

    plot_butterfly!(f[1, 2], d_topo; positions=positions)

    plot_topoplot!(f[2, 1], data[:, 150, 1]; positions=positions, t=150)
    plot_topoplotseries!(f[2, 2], d_topo, 0.1; positions=positions, layout = (; useColorbar=true))
    plot_erpgrid!(f[3, 1], data, pos)

   
    times = -0.099609375:0.001953125:1.0
    plot_erpimage!(f[3, 2], times, d_singletrial)

    plot_parallelcoordinates!(f[4, 2], uf_5chan, [1, 2, 3, 4, 5]; mapping=(; color=:coefname), layout=(; legendPosition=:bottom))

    for (label, layout) in zip(["A", "B", "C", "D", "E", "F", "G", "H"], 
        [f[1, 1], f[1, 2], f[2, 1], f[2, 2], f[3, 1], f[3, 2], f[4, 1], f[4, 2]])
        Label(layout[1, 1, TopLeft()], label,
            fontsize=26,
            font=:bold,
            padding=(0, 5, 5, 0),
            halign=:right)
    end
    f
end


@testset "testing combined figure" begin
    include("../docs/example_data.jl")
    d_topo, positions = example_data("TopoPlots.jl")
    uf_deconv = example_data("UnfoldLinearModelContinuousTime")
    uf = example_data("UnfoldLinearModel")
    results = coeftable(uf)
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched=true)

    f = Figure(resolution=(2000, 2000))

    plot_butterfly!(f[1, 1:3], d_topo; positions=positions)

    pvals = DataFrame(
        from=[0.1, 0.15],
        to=[0.2, 0.5],
        # if coefname not specified, line should be black
        coefname=["(Intercept)", "category: face"]
    )
    plot_erp!(f[2, 1:2], results, extra=(;
        categoricalColor=false,
        categoricalGroup=false,
        pvalue=pvals,
        stderror=true))


    plot_designmatrix!(f[2, 3], designmatrix(uf))

    plot_topoplot!(f[3, 1], collect(1:64); positions=positions, visual=(; colormap=:viridis))
    plot_topoplotseries!(f[4, 1:3], d_topo, 0.1; positions=positions, layout = (; useColorbar=true))

    res_effects = effects(Dict(:continuous => -5:0.5:5), uf_deconv)

    plot_erp!(f[2, 4:5], res_effects;
        mapping=(; y=:yhat, color=:continuous, group=:continuous),
        extra=(; showLegend=true,
            categoricalColor=false,
            categoricalGroup=true),
        legend=(; nbanks=2),
        layout=(; legendPosition=:right))



    plot_parallelcoordinates!(f[3, 2:3], uf_5chan, [1, 2, 3, 4, 5]; mapping=(; color=:coefname), layout=(; legendPosition=:bottom))

    times = -0.099609375:0.001953125:1.0
    plot_erpimage!(f[1, 4:5], times, d_singletrial)

    plot_circulareegtopoplot!(f[3:4, 4:5], d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
        positions=positions, predictor=:time, predictorBounds=[-0.3, 0.5])

    f
    #save("test.png", f)
end


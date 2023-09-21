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
    plot_topoplotseries!(f[4, 1:3], d_topo, 0.1; positions=positions, mapping=(; label=:channel))


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
        positions=positions, predictor=:time, extra=(; predictorBounds=[-0.3, 0.5]))

    f
end
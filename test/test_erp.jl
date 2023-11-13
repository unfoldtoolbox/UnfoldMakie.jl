@testset "basic with results" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
    data = reshape(data, (1, size(data)...))
    f = @formula 0 ~ 1 + condition + continuous
    se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)

    m = fit(
        UnfoldModel,
        Dict(Any => (f, range(0, step = 1 / 100, length = size(data, 2)))),
        evts,
        data,
        solver = se_solver,
    )
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

    # ## Plot the results
    plot_erp(results; :stderror => true)
end


@testset "basic with res_effects" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
    data = reshape(data, (1, size(data)...))
    f = @formula 0 ~ 1 + condition + continuous
    se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true)

    m = fit(
        UnfoldModel,
        Dict(Any => (f, range(0, step = 1 / 100, length = size(data, 2)))),
        evts,
        data,
        solver = se_solver,
    )
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

    # ## Plot the results
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous),
        legend = (; nbanks = 2),
        layout = (; legendPosition = :right),
        showLegend = true,
        categoricalColor = false,
        categoricalGroup = true,
    )
end


@testset "erp plot in GridLayout" begin
    f = Figure(resolution=(1200, 1400))
    ga = f[1, 1] = GridLayout()

    include("../docs/example_data.jl")
    uf = example_data("UnfoldLinearModel")
    results = coeftable(uf)

    pvals = DataFrame(
        from=[0.1, 0.15],
        to=[0.2, 0.5],
        # if coefname not specified, line should be black
        coefname=["(Intercept)", "category: face"]
    )
    plot_erp!(ga, results, extra=(;
        categoricalColor=false,
        categoricalGroup=false,
        pvalue=pvals,
        stderror=true)) 

    f
end

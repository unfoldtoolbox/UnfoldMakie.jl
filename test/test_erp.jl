include("../docs/example_data.jl")
@testset "ERP plot with Results data" begin
    m = example_data("UnfoldLinearModel")
    results = coeftable(m)
    plot_erp(results; :stderror => true)
end

@testset "ERP plot with and withour error ribbons" begin
    f = Figure()
    m = example_data("UnfoldLinearModel")
    results = coeftable(m)
    results.coefname =
        replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
    results = filter(row -> row.coefname != "continuous", results)
    plot_erp!(
        f[1, 1],
        results;
        :stderror => false,
        mapping = (; color = :coefname => "Conditions"),
    )

    plot_erp!(
        f[2, 1],
        results;
        :stderror => true,
        mapping = (; color = :coefname => "Conditions"),
    )

    ax = Axis(f[2, 1], width = Relative(1), height = Relative(1))
    xlims!(ax, [-0.04, 1])
    ylims!(ax, [-0.04, 1])
    hidespines!(ax)
    hidedecorations!(ax)
    text!(0.98, 0.2, text = "* Confidence\nintervals", align = (:right, :top))
    for (label, layout) in zip(["bad", "good"], [f[1, 1], f[2, 1]])
        Label(
            layout[1, 1:2, TopRight()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, 0, 0, 0),
            halign = :right,
        )
    end
    f
    #save("erp.png", f)
end

@testset "ERP plot with res_effects without colorbar" begin
    m = example_data("UnfoldLinearModel")
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

    # ## Plot the results
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous),
        legend = (; nbanks = 2),
        layout = (; legend_position = :right, show_legend = false),
        categorical_color = false,
        categorical_group = true,
    )
end

@testset "ERP plot with res_effects" begin
    m = example_data("UnfoldLinearModel")
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

    # ## Plot the results
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous),
        legend = (; nbanks = 2),
        layout = (; legend_position = :right, show_legend = true),
        categorical_color = false,
        categorical_group = true,
    )
end


@testset "ERP plot in GridLayout" begin
    f = Figure(resolution = (1200, 1400))
    ga = f[1, 1] = GridLayout()

    include("../docs/example_data.jl")
    uf = example_data("UnfoldLinearModel")
    results = coeftable(uf)

    pvals = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5],
        # if coefname not specified, line should be black
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(
        ga,
        results;
        categorical_color = false,
        categorical_group = false,
        pvalue = pvals,
        stderror = true,
    )

    f
end

@testset "ERP plot with borderless legend" begin
    f = Figure(resolution = (1200, 1400))
    ga = f[1, 1] = GridLayout()

    m = example_data("UnfoldLinearModel")

    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

    plot_erp!(ga, results; :stderror => true)

    f
end

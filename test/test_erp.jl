using AlgebraOfGraphics: group
include("../docs/example_data.jl")
m = example_data("UnfoldLinearModel")

@testset "ERP plot with Results data" begin
    results = coeftable(m)
    plot_erp(results; :stderror => true)
end

@testset "ERP plot, faceting by two columns" begin
    results = coeftable(m)
    results.group = push!(repeat(["A", "B"], inner = 67), "A")
    plot_erp(results; mapping = (; col = :group))
end

@testset "ERP plot with and withour error ribbons" begin
    f = Figure()
    results = coeftable(m)
    results.coefname =
        replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
    results = filter(row -> row.coefname != "continuous", results)
    plot_erp!(
        f[1, 1],
        results;
        axis = (title = "Bad example", titlegap = 12),
        :stderror => false,
        mapping = (; color = :coefname => "Conditions"),
    )
    plot_erp!(
        f[2, 1],
        results;
        axis = (title = "Good example", titlegap = 12),
        :stderror => true,
        mapping = (; color = :coefname => "Conditions"),
    )

    ax = Axis(f[2, 1], width = Relative(1), height = Relative(1))
    xlims!(ax, [-0.04, 1])
    ylims!(ax, [-0.04, 1])
    hidespines!(ax)
    hidedecorations!(ax)
    text!(0.98, 0.2, text = "* Confidence\nintervals", align = (:right, :top))
    f
    #save("erp.png", f)
end

@testset "Effect plot without colorbar" begin
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous),
        legend = (; nbanks = 2),
        layout = (; legend_position = :right, show_legend = false),
        categorical_color = false,
        categorical_group = true,
    )
end


@testset "Effect plot" begin
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)

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
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()

    results = coeftable(m)
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
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()


    m = example_data("UnfoldLinearModel")
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    plot_erp!(ga, results; :stderror => true)

    f
end

@testset "ERP plot with p-values" begin

    results = coeftable(m)
    pvals = DataFrame(
        from = [0.1, 0.3],
        to = [0.5, 0.7],
        coefname = ["(Intercept)", "condition: face"], # if coefname not specified, line should be black
    )
    plot_erp(results; :pvalue => pvals)
end

@testset "ERP plot with 7 channels faceted" begin
    m7 = example_data("7channels")
    results7 = coeftable(m7)
    plot_erp(results7, mapping = (; col = :channel, group = :channel))
end

@testset "Effect plot, faceted" begin
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    plot_erp(res_effects; mapping = (; y = :yhat, color = :continuous, col = :channel))
end


@testset "Effect plot, faceted channels" begin #bug
    results = coeftable(m)
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    #res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    res_effects.channel = float.(push!(repeat([1, 2], 472), 1))
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, group = :channel, col = :channel),
        #mapping = (; y = :yhat, col = :channel, group = :channel, color = :channel), 
        #categorical_color = false,
        #categorical_group = true
    )
end

#= @testset "ERP plot with legend and colorbar" begin
    results = coeftable(m)
    coefnames = unique(results.coefname)

    f = Figure(size = (1000, 400))
    ga = f[1, 1] = GridLayout()

    f2 = plot_erp!(
        ga,
        effects(Dict(:condition => ["car", "face"], :continuous => -5:5), m);
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        legend = (; valign = :top, halign = :right, tellwidth = false),
        categorical_color = false,
        axis = (
            title = "Marginal effects",
            titlegap = 12,
            xlabel = "Time [s]",
            ylabel = "Amplitude [μV]",
            xlabelsize = 16,
            ylabelsize = 16,
            xgridvisible = false,
            ygridvisible = false,
        ),
        layout = (; showlegend = false),
    )
    f

    # Workaround to separate legend and colorbar (will be fixed in a future UnfoldMakie version)
    legend = f2.content[2].content
    f2[:, 1] = legend
    f
end =#

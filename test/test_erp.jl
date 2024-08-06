using AlgebraOfGraphics: group
include("../docs/example_data.jl")
m = example_data("UnfoldLinearModel")
results = coeftable(m)
res_effects = effects(Dict(:continuous => -5:0.5:5), m)
res_effects2 = effects(Dict(:condition => ["car", "face"], :continuous => -5:5), m)
dat, positions = TopoPlots.example_data()

@testset "ERP plot: DataFrame data" begin
    plot_erp(results)
end

@testset "ERP plot: Matrix data" begin
    plot_erp(dat[1, :, 1:2]')
end

@testset "ERP plot: Array data" begin
    plot_erp(dat[1, :, 1])
end

@testset "ERP plot: Array data with times vector" begin
    times = range(0, step = 100, length = size(dat, 2))
    plot_erp(times, dat[1, :, 1], axis = (; xtickformat = "{:d}"))
end

@testset "ERP plot: stderror error" begin
    plot_erp(results; :stderror => true)
end

@testset "ERP plot: standart errors in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    plot_erp!(ga, results; :stderror => true)
    f
end

@testset "ERP plot: faceting by two columns" begin
    results = coeftable(m)
    results.group = push!(repeat(["A", "B"], inner = 67), "A")
    plot_erp(results; mapping = (; col = :group))
end

@testset "ERP plot: with and withour error ribbons" begin
    results = coeftable(m)
    f = Figure()
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

@testset "ERP plot: in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()

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
        significance = pvals,
        stderror = true,
    )
    f
end

@testset "ERP plot with significance" begin
    pvals = DataFrame(
        from = [0.1, 0.3],
        to = [0.5, 0.7],
        coefname = ["(Intercept)", "condition: face"], # if coefname not specified, line should be black
    )
    plot_erp(results; :significance => pvals)
end

@testset "ERP plot: 7 channels faceted" begin
    m7 = example_data("7channels")
    results7 = coeftable(m7)
    plot_erp(results7, mapping = (; col = :channel, group = :channel))
end


@testset "ERP plot: with colorbar and legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        categorical_color = false,
    )
end

@testset "ERP plot: rename legend" begin
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
    f
end

@testset "Effect plot" begin #where is legend here??
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous),
        legend = (; nbanks = 2),
        layout = (; legend_position = :right),
        categorical_color = false,
        categorical_group = true,
    )
end

@testset "Effect plot: faceted" begin #bug
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    plot_erp(res_effects; mapping = (; y = :yhat, color = :continuous, col = :channel))
end

@testset "Effect plot: faceted channels" begin #bug
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    #res_effects.channel = float.(push!(repeat([1, 2], 472), 1))
    plot_erp(res_effects; mapping = (; y = :yhat, group = :channel, col = :channel))
end

@testset "Effect plot: no colorbar and legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; show_legend = true, use_legend = false, use_colorbar = false),
        categorical_color = false,
    )
end

@testset "Effect plot: no colorbar" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = true, use_colorbar = false),
        categorical_color = false,
    )
end

@testset "Effect plot: no legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = false, use_colorbar = true),
        categorical_color = false,
    )
end

@testset "Effect plot: no colorbar and no legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = false, use_colorbar = false),
        categorical_color = false,
    )
end

@testset "Effect plot: yes colorbar and yes legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = true, use_colorbar = true),
        categorical_color = false,
    )
end

@testset "Effect plot: move legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        legend = (; valign = :bottom, halign = :right, tellwidth = false),
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
    )
end

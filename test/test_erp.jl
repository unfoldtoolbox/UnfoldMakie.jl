using Unfold: stderror
using AlgebraOfGraphics: group
m = UnfoldMakie.example_data("UnfoldLinearModel")

results = coeftable(m)

res_effects = effects(Dict(:continuous => -5:0.5:5), m)
res_effects2 = effects(Dict(:condition => ["car", "face"], :continuous => -5:5), m)
res_effects3 = effects(Dict(:condition => ["car", "face"], :continuous => 75:20:300), m)
topo_array, positions = TopoPlots.example_data()
p1, evts = UnfoldSim.predef_eeg(; noiselevel = 8)

m7 = UnfoldMakie.example_data("7channels")
results7 = coeftable(m7)
significancevalues = DataFrame(
    from = [0.01, 0.2, 0.1],
    to = [0.3, 0.4, 0.2],
    coefname = ["(Intercept)", "condition: face", "continuous"], # if coefname not specified, line should be black
)

@testset "ERP plot: DataFrame data" begin
    plot_erp(results)
end

@testset "ERP plot: Matrix data" begin
    plot_erp(topo_array[1, 1:100, 1:2]')
end

@testset "ERP plot: Array data" begin
    plot_erp(topo_array[1, :, 1])
end

@testset "ERP plot: zero matrix with color mapping" begin
    plot_erp(zeros(10, 10))
end

@testset "ERP plot: zero matrix with no color mapping" begin
    plot_erp(zeros(10, 10), mapping = (; color = nothing))
end

@testset "ERP plot: zero matrix with solid color" begin
    plot_erp(zeros(10, 10), mapping = (; color = nothing), visual = (; color = "red"))
end

@testset "ERP plot: rename xlabel" begin
    plot_erp(results; axis = (; xlabel = "test"))
end

@testset "ERP plot: xlabelvisible" begin
    plot_erp(results; axis = (; xlabelvisible = false, xticklabelsvisible = false))
end

@testset "ERP plot: Array data with times vector" begin
    times = range(0, step = 100, length = size(topo_array, 2))
    plot_erp(times, topo_array[1, :, 1])
end

@testset "ERP plot: stderror error" begin
    plot_erp(results; stderror = true)
end

@testset "ERP plot: standart errors in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    plot_erp!(ga, results; stderror = true)
    f
end

@testset "ERP plot: faceting by two columns and stderrors" begin
    results.group = repeat(["A", "B"], inner = 66)
    plot_erp(results; mapping = (; col = :group))

    plot_erp(results; mapping = (; col = :group), stderror = true)
end

@testset "ERP plot: with and without error ribbons" begin
    local results2 = copy(results)
    results2.coefname =
        replace(results2.coefname, "condition: face" => "face", "(Intercept)" => "car")
    results2 = filter(row -> row.coefname != "continuous", results2)

    f = Figure()
    plot_erp!(
        f[1, 1],
        results2;
        axis = (; title = "Bad example", titlegap = 12),
        stderror = false,
        mapping = (; color = :coefname => "Conditions"),
    )
    plot_erp!(
        f[2, 1],
        results2;
        axis = (title = "Good example", titlegap = 12),
        stderror = true,
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


@testset "ERP plot with significance" begin
    plot_erp(results; :significance => significancevalues)
end

@testset "ERP plot with significance: in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()

    significancevalues = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5],
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(ga, results; significance = significancevalues, stderror = true)
    f
end

@testset "ERP plot with significance_vspan" begin
    plot_erp(
        results;
        :significance => DataFrame(
            from = [0.01, 0.25, 0.35],
            to = [0.2, 0.29, 0.4],
            coefname = ["(Intercept)", "condition: face", "continuous"], # if coefname not specified, line should be black
        ),
        significance_vspan = (; alpha = 0.1),
    )
end

@testset "ERP plot with significance_lines" begin
    plot_erp(
        results;
        :significance => significancevalues,
        sigifnicance_visual = :lines,
        significance_lines = (; linewidth = 0.001, gap = 0.1),
    )
end

@testset "ERP plot with significance_lines 2" begin
    plot_erp(
        results;
        :significance => significancevalues,
        sigifnicance_visual = :lines,
        significance_lines = (; linewidth = 0.01, gap = 0.6),
    )
end

@testset "ERP plot with both significance" begin
    plot_erp(
        results;
        :significance => DataFrame(
            from = [0.01, 0.25, 0.35],
            to = [0.2, 0.29, 0.4],
            coefname = ["(Intercept)", "condition: face", "continuous"], # if coefname not specified, line should be black
        ),
        sigifnicance_visual = :both,
        significance_vspan = (; alpha = 0.1),
        significance_lines = (; linewidth = 0.001, gap = 0.2),
    )
end

@testset "ERP plot: 7 channels faceted" begin
    plot_erp(results7, mapping = (; col = :channel, group = :channel))
end

@testset "ERP plot: rename legend" begin
    plot_erp(
        results;
        axis = (title = "Bad example", titlegap = 12),
        mapping = (; color = :coefname => "Conditions"),
    )
end

@testset "ERP plot: Facet sorting" begin
    sorting1 = ["face", "car"] # check 
    sorting2 = ["car", "face"]

    f = Figure()
    plot_erp!(
        f[1, 1],
        res_effects2;
        mapping = (;
            col = :condition => sorter(sorting1),
            color = :continuous,
            group = :continuous,
        ),
    )
    plot_erp!(
        f[2, 1],
        res_effects2;
        mapping = (;
            col = :condition => sorter(sorting2),
            color = :continuous,
            group = :continuous,
        ),
    )
    f
end

@testset "ERP plot: colors and lines in cycled theme" begin
    with_theme(
        Theme(
            palette = (color = [:red, :green], linestyle = [:dash, :dot]),
            Lines = (cycle = Cycle([:color, :linestyle], covary = true),),
        ),
    ) do
        plot_erp(results)

    end
end

begin
    evts.condition = evts.condition .== "face"

    basisfunction = firbasis(τ = (-0.1, 0.5), sfreq = 100; interpolate = false)
    f = @formula 0 ~ 1 + condition + continuous
    m = fit(UnfoldModel, [Any => (f, basisfunction)], evts, p1, eventcolumn = "type")
    eff = effects(Dict(:condition => [true, false]), m)
    @testset "ERP plot: color with Boolean values" begin
        plot_erp(eff; mapping = (; color = :condition,))
    end

    @testset "ERP plot: no color specified" begin
        plot_erp(eff; mapping = (; col = :condition,))
    end
    @testset "ERP plot: color is specified" begin
        plot_erp(eff; mapping = (; col = :condition,), visual = (; color = :red))
    end
end

begin
    @testset "ERP plot: legend positons right" begin
        plot_erp(
            results;
            legend = (;
                orientation = :horizontal,
                titleposition = :left,
                position = :right,
            ),
        )
    end
    @testset "ERP plot: legend positons bottom" begin
        plot_erp(
            results;
            legend = (;
                orientation = :horizontal,
                titleposition = :left,
                position = :bottom,
            ),
        )
    end
    @testset "ERP plot: legend positons bottom" begin
        f = Figure()
        ga = f[1, 1] = GridLayout()
        plot_erp(results; legend = (; orientation = :horizontal, titleposition = :left))
        f
    end
end

@testset "erp: nticks for x and y" begin
    plot_erp(results; nticks = 6)                   # both axes 6
    plot_erp(results; nticks = (5, 7))              # x=5, y=7
    plot_erp(results; nticks = (x = 5, y = 7))          # explicit
end

@testset "erp: xtickformat usage" begin
    plot_erp(results; axis = (; xtickformat = "{:.2f}ms"))
end

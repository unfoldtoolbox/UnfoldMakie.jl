using Unfold: stderror
using AlgebraOfGraphics: group
m = UnfoldMakie.example_data("UnfoldLinearModel")

results = coeftable(m)
res_effects = effects(Dict(:continuous => -5:0.5:5), m)
res_effects2 = effects(Dict(:condition => ["car", "face"], :continuous => -5:5), m)
dat, positions = TopoPlots.example_data()

m7 = UnfoldMakie.example_data("7channels")
results7 = coeftable(m7)
pvals = DataFrame(
    from = [0.01, 0.2, 0.1],
    to = [0.3, 0.4, 0.2],
    coefname = ["(Intercept)", "condition: face", "continuous"], # if coefname not specified, line should be black
)

@testset "ERP plot: DataFrame data" begin
    plot_erp(results)
end

@testset "ERP plot: Matrix data" begin
    plot_erp(dat[1, 1:100, 1:2]')
end

@testset "ERP plot: Array data" begin
    plot_erp(dat[1, :, 1])
end

@testset "ERP plot: no color" begin
    plot_erp(zeros(10, 10), mapping = (; color = nothing))
end

@testset "ERP plot: rename xlabel" begin
    plot_erp(results; axis = (; xlabel = "test"))
end

@testset "ERP plot: xlabelvisible" begin
    plot_erp(results; axis = (; xlabelvisible = false, xticklabelsvisible = false))
end

@testset "ERP plot: Array data with times vector" begin
    times = range(0, step = 100, length = size(dat, 2))
    plot_erp(times, dat[1, :, 1], axis = (; xtickformat = "{:d}"))
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

@testset "ERP plot: faceting by two columns" begin
    results = coeftable(m)
    results.group = push!(repeat(["A", "B"], inner = 67), "A")
    plot_erp(results; mapping = (; col = :group))
end

@testset "ERP plot: faceting by two columns with stderror" begin
    results = coeftable(m)
    results.group = push!(repeat(["A", "B"], inner = 67), "A")
    plot_erp(results; mapping = (; col = :group), stderror = true)
end

@testset "ERP plot: with and without error ribbons" begin
    results = coeftable(m)
    results.coefname =
        replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
    results = filter(row -> row.coefname != "continuous", results)

    f = Figure()
    plot_erp!(
        f[1, 1],
        results;
        axis = (; title = "Bad example", titlegap = 12),
        stderror = false,
        mapping = (; color = :coefname => "Conditions"),
    )
    plot_erp!(
        f[2, 1],
        results;
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

@testset "ERP plot: in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()

    pvals = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5],
        # if coefname not specified, line should be black
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(ga, results; significance = pvals, stderror = true)
    f
end

@testset "ERP plot with significance" begin
    plot_erp(results; :significance => pvals)
end

#= @testset "ERP plot with significance 2" begin
    plot_erp(results; :significance => pvals, sigtype = :vspan)
end =#

@testset "ERP plot: 7 channels faceted" begin
    plot_erp(results7, mapping = (; col = :channel, group = :channel))
end

@testset "ERP plot: rename legend" begin
    f = Figure()
    results = coeftable(m)
    results.coefname =
        replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
    results = filter(row -> row.coefname != "continuous", results)
    plot_erp!(
        f,
        results;
        axis = (title = "Bad example", titlegap = 12),
        mapping = (; color = :coefname => "Conditions"),
    )
    f
end

@testset "ERP plot: Facet sorting" begin
    data, evts = UnfoldSim.predef_eeg()

    m = fit(
        UnfoldModel,
        [
            "car" => (@formula(0 ~ 1 + continuous), firbasis((-0.1, 1), 100)),
            "face" => (@formula(0 ~ 1 + continuous), firbasis((-0.1, 1), 100)),
        ],
        evts,
        data;
        eventcolumn = :condition,
    )
    eff = effects(Dict(:continuous => 75:20:300), m)

    sorting1 = ["face", "car"] # check 
    sorting2 = ["car", "face"]

    f = Figure()
    plot_erp!(
        f[1, 1],
        eff;
        mapping = (;
            col = :eventname => sorter(sorting1),
            color = :continuous,
            group = :continuous,
        ),
    )
    plot_erp!(
        f[2, 1],
        eff;
        mapping = (;
            col = :eventname => sorter(sorting2),
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
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 8)
    evts.condition = evts.condition .== "face"

    basisfunction = firbasis(τ = (-0.1, 0.5), sfreq = 100; interpolate = false)
    f = @formula 0 ~ 1 + condition + continuous
    m = fit(UnfoldModel, [Any => (f, basisfunction)], evts, data, eventcolumn = "type")
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

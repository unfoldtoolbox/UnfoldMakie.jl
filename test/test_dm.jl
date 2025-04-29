uf = UnfoldMakie.example_data("UnfoldLinearModel")
td = UnfoldMakie.example_data("UnfoldTimeExpanded")

df, evts = UnfoldSim.predef_eeg()
f = @formula 0 ~ 1 + condition + continuous
m = fit(
    UnfoldModel,
    @formula(0 ~ 1 + condition),
    evts,
    df,
    firbasis((-0.1, 1), 100);
    fit = false,
)

@testset "dm: basic" begin
    plot_designmatrix(designmatrix(uf))
end

@testset "dm: sort data" begin
    plot_designmatrix(designmatrix(uf); sort_data = true)
end

@testset "dm: in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    plot_designmatrix!(ga, designmatrix(uf); sort_data = true)
    f
end

@testset "dm: ticks specified" begin
    plot_designmatrix(designmatrix(uf); xticks = 10, sort_data = false)
end

@testset "dm: toplabels" begin
    basisfunction = firbasis(τ = (-0.4, 0.8), sfreq = 5, name = "stimulus")
    #basisfunction = firbasis(τ = (-0.4, -0.3), sfreq = 10, name = "")
    bfDict = [Any => (f, basisfunction)]
    td = fit(UnfoldModel, bfDict, evts, df)
    plot_designmatrix(designmatrix(td))
end

@testset "dm: xticks = 0" begin
    plot_designmatrix(designmatrix(m), xticks = 0)
end

@testset "dm: xticks = 1" begin
    plot_designmatrix(designmatrix(m), xticks = 1)
end

@testset "dm: xticks = 2" begin
    plot_designmatrix(designmatrix(m), xticks = 2)
end

@testset "dm: xticks = 10" begin
    plot_designmatrix(designmatrix(m), xticks = 10)
end

@testset "dm: xticks = -1" begin
    @test_throws AssertionError begin
        plot_designmatrix(designmatrix(m), xticks = -1)
    end
end
#Unfold.SimpleTraits.istrait(Unfold.ContinuousTimeTrait{typeof(td)})
#Unfold.SimpleTraits.istrait(Unfold.ContinuousTimeTrait{typeof(uf)})

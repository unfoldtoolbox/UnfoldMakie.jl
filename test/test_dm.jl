uf = example_data("UnfoldLinearModel")
td = example_data("UnfoldTimeExpanded")

@testset "basic" begin
    plot_designmatrix(designmatrix(uf))
end

@testset "sort data" begin
    plot_designmatrix(designmatrix(uf); sort_data = true)
end

@testset "designmatrix plot in GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    plot_designmatrix!(ga, designmatrix(uf); sort_data = true)
    f
end

@testset "ticks specified" begin
    plot_designmatrix(designmatrix(uf); xticks = 10, sort_data = false)
end

@testset "hierarchical labels (bugged)" begin
    df, evts = UnfoldSim.predef_eeg()
    f = @formula 0 ~ 1 + condition + continuous
    basisfunction = firbasis(τ = (-0.4, 0.8), sfreq = 5, name = "stimulus")
    #basisfunction = firbasis(τ = (-0.4, -0.3), sfreq = 10, name = "")
    bfDict = [Any => (f, basisfunction)]
    td = fit(UnfoldModel, bfDict, evts, df)
    plot_designmatrix(designmatrix(td))
end


#Unfold.SimpleTraits.istrait(Unfold.ContinuousTimeTrait{typeof(td)})
#Unfold.SimpleTraits.istrait(Unfold.ContinuousTimeTrait{typeof(uf)})

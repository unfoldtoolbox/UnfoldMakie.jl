df, pos = UnfoldMakie.example_data("TopoPlots.jl")
n = length(pos)
est = randn(n)
unc = abs.(randn(n)) .* 0.3

@testset "triple_CI: positions input" begin
    plot_triple_CI(est, unc; positions = pos)
end

@testset "triple_CI: draw into a GridPosition" begin
    f = Figure()
    plot_triple_CI!(f[1, 1], est, unc; positions = pos)
end

@testset "triple_CI: config group overrides merge with default" begin
    plot_triple_CI(
        est, unc;
        positions = pos,
        layout = (; topo_size = 180),
        colorbar = (; label = "µV", labelsize = 19),
        visual = (; colormap = :roma),
    )
end

@testset "triple_CI: visual.colorrange overrides the shared range" begin
    plot_triple_CI(est, unc; positions = pos, visual = (; colorrange = (-2, 2)))
end

@testset "triple_CI: custom uncertainty label/perc" begin
    plot_triple_CI(est, unc; positions = pos, uncert_label = "91% CI")
end

@testset "triple_CI: errors when positions/labels not defined" begin
    @test_throws ErrorException plot_triple_CI(est, unc)
end

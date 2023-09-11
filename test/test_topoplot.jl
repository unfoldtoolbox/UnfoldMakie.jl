include("setup.jl")
@testset "testing topoplot" begin
    data, positions = TopoPlots.example_data()
    plot_topoplot(data[:, 150, 1]; positions=positions, t=150)
end

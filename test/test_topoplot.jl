data, positions = TopoPlots.example_data()

@testset "testing topoplot" begin
    plot_topoplot(data[:, 150, 1]; positions=positions)
end

@testset "testing topoplot" begin
    f = Figure()
    plot_topoplot!(f[1, 1], data[:, 150, 1]; positions=positions)
end
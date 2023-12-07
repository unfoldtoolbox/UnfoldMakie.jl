data, positions = TopoPlots.example_data()

@testset "topoplot basic" begin
    plot_topoplot(data[:, 50, 1]; positions=positions)
end

@testset "topoplot without legend" begin
    plot_topoplot(data[:, 50, 1]; positions=positions, layout = (; show_legend = false))
end

@testset "topoplot with xlabel" begin
    plot_topoplot(data[:, 50, 1]; positions=positions, xlabel = "[50 ms]")
end

@testset "topoplot with GridLayout" begin
    f = Figure()
    plot_topoplot!(f[1, 1], data[:, 150, 1]; positions=positions)
    f
end
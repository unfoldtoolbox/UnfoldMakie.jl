dat, positions = TopoPlots.example_data()

@testset "topoplot basic" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, axis = (; title = "topoplot"))
end

@testset "topoplot without legend" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, layout = (; show_legend = false))
end

@testset "topoplot with xlabel" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, axis = (; xlabel = "[50 ms]"))
end

@testset "topoplot with GridLayout" begin
    f = Figure()
    plot_topoplot!(f[1, 1], dat[:, 150, 1]; positions = positions)
    f
end

@testset "topoplot with labels" begin
    labels = ["s$i" for i = 1:size(dat[:, 150, 1], 1)]
    plot_topoplot(dat[:, 150, 1]; positions = positions, labels = labels)
end

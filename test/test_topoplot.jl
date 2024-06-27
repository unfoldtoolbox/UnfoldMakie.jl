dat, positions = TopoPlots.example_data()

@testset "topoplot basic" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, axis = (; title = "topoplot"))
end

@testset "topoplot: no legend" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, layout = (; show_legend = false))
end

@testset "topoplot: xlabel" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, axis = (; xlabel = "[50 ms]"))
end

@testset "topoplot: GridLayout" begin
    f = Figure()
    plot_topoplot!(f[1, 1], dat[:, 150, 1]; positions = positions)
    f
end

@testset "topoplot: labels" begin
    labels = ["s$i" for i = 1:size(dat[:, 150, 1], 1)]
    plot_topoplot(dat[:, 150, 1]; positions = positions, labels = labels)
end

@testset "topoplot: AbstractMatrix" begin
    plot_topoplot(zeros(1:128))
end

@testset "topoplot: ViewArray" begin
    d = Dict(:a => 11, :b => 12, :c => 13)
    plot_topoplot(view(d, [:a, :c])) 
end
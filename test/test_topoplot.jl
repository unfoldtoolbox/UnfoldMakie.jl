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
    d = zeros(1:128)
    p = [(rand(), rand()) for _ = 1:size(d, 1)]
    plot_topoplot(d; positions = d)
end

@testset "topoplot: ViewArray" begin
    d = Dict(:y => (11, 12), :b => (11, 12), :c => (11, 12))
    v = view(d, [:y, :c])
    plot_topoplot(d; positions = rand(2))
end

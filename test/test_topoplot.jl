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

@testset "topoplot: GridSubposition" begin
    f = Figure()
    data_for_topoplot = UnfoldMakie.eeg_array_to_dataframe(rand(10)')
    plot_topoplot!(
        f[1, 1][1, 1],
        data_for_topoplot;
        positions = rand(Point2f, 10),
        labels = string.(1:10),
    )
    f
end

@testset "topoplot: AbstractMatrix" begin
    d = rand(128)
    p = rand(Point2f, 128)
    plot_topoplot(d; positions = p)
end

@testset "topoplot: ViewArray" begin
    d = DataFrame(:estimate => rand(20), :label => string.(1:20))

    plot_topoplot(@view(d[1:10, :]); positions = rand(Point2f, 10))
end

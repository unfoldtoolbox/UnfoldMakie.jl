dat, positions = TopoPlots.example_data()
data_for_topoplot = UnfoldMakie.eeg_array_to_dataframe(rand(10)')

@testset "topoplot: basic" begin
    plot_topoplot(dat[:, 50, 1], pos)
end

@testset "topoplot: data input as DataFrame" begin
    plot_topoplot(data_for_topoplot, positions[1:10], axis = (; title = "Topoplot"))
end

@testset "topoplot: data input as AbstractVector" begin
    d = rand(128)
    p = rand(Point2f, 128)
    plot_topoplot(d, p)
end

@testset "topoplot: data input as SubDataFrame" begin
    d = DataFrame(:estimate => rand(20), :label => string.(1:20))
    d1 = @view(d[1:10, :])
    plot_topoplot(d1, rand(Point2f, 10))
end

@testset "topoplot: no legend" begin
    plot_topoplot(dat[:, 50, 1], positions; layout = (; show_legend = false))
end

@testset "topoplot: xlabel" begin
    plot_topoplot(dat[:, 50, 1], positions; axis = (; xlabel = "[50 ms]"))
end

@testset "topoplot: GridLayout" begin
    f = Figure()
    plot_topoplot!(f[1, 1], dat[:, 150, 1], positions)
    f
end

@testset "topoplot: labels" begin
    labels = ["s$i" for i = 1:size(dat[:, 150, 1], 1)]
    plot_topoplot(dat[:, 150, 1], positions; labels = labels)
end

@testset "topoplot: GridSubposition" begin
    f = Figure()
    plot_topoplot!(
        f[1, 1][1, 1],
        data_for_topoplot,
        rand(Point2f, 10);
        labels = string.(1:10),
    )
    f
end

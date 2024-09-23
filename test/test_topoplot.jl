dat, positions = TopoPlots.example_data()
data_for_topoplot = UnfoldMakie.eeg_array_to_dataframe(rand(10)')

@testset "topoplot: basic" begin
    plot_topoplot(dat[:, 50, 1]; positions)
end

@testset "topoplot: data input as DataFrame" begin
    plot_topoplot(
        data_for_topoplot;
        positions = positions[1:10],
        axis = (; title = "Topoplot"),
    )
end

@testset "topoplot: data input as AbstractVector" begin
    d = rand(128)
    p = rand(Point2f, 128)
    plot_topoplot(d; positions = p)
end

@testset "topoplot: data input as SubDataFrame" begin
    d = DataFrame(:estimate => rand(20), :label => string.(1:20))
    d1 = @view(d[1:10, :])
    plot_topoplot(d1; positions = rand(Point2f, 10))
end

@testset "topoplot: highliht an electrode" begin
    plot_topoplot(dat[:, 50, 1]; positions, high_chan = 2)
end

@testset "topoplot: highliht several electrodes" begin
    plot_topoplot(dat[:, 50, 1]; positions, high_chan = [1, 2])
end

@testset "topoplot: no legend" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, layout = (; use_colorbar = false))
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
    plot_topoplot(dat[:, 150, 1], positions = positions; labels = labels)
end

@testset "topoplot: GridSubposition" begin
    f = Figure()
    plot_topoplot!(
        f[1, 1][1, 1],
        data_for_topoplot;
        positions = rand(Point2f, 10),
        labels = string.(1:10),
    )
    f
end

@testset "topoplot: positions through labels" begin
    plot_topoplot(dat[1:19, 50, 1]; labels = TopoPlots.CHANNELS_10_20)
end


begin
    function topoplot_indicator!(f, ix)
        x = zeros(128)
        x[ix] = 1
        clist = [:gray, :darkred][Int.(x .+ 1)]
        ax =
            f[1, 1] = Axis(
                f,
                width = Relative(0.4),
                height = Relative(0.4),
                halign = 1.2,
                valign = 1,
                aspect = 1,
            )

        UnfoldMakie.TopoPlots.eeg_topoplot!(
            ax,
            x;
            positions = pos,
            enlarge = 0.9,
            label_scatter = (;
                color = clist,
                markersize = ((x .+ 0.25) .* 40) ./ 5,
                strokewidth = 0,
            ),
            interpolation = UnfoldMakie.TopoPlots.NullInterpolator(),
        )
        hidespines!(ax)
        hidedecorations!(ax)
    end

end

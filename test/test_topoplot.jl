dat, positions = TopoPlots.example_data()
data_for_topoplot = UnfoldMakie.eeg_array_to_dataframe(rand(10)')

#= 
@testset "eeg_topoplot: colorbar" begin
    f, a, h= TopoPlots.eeg_topoplot(1:10, positions=rand(Point2f, 10))
    Colorbar(f[1,2], h)
end =#

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

@testset "topoplot: highlight an electrode" begin
    plot_topoplot(dat[:, 50, 1]; positions, high_chan = 2)
end

@testset "topoplot: highlight several electrodes" begin
    plot_topoplot(dat[:, 50, 1]; positions, high_chan = [1, 2])
end

@testset "topoplot: no legend" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, layout = (; use_colorbar = false))
end

@testset "topoplot: xlabel" begin
    plot_topoplot(dat[:, 50, 1]; positions = positions, axis = (; xlabel = "[50 ms]"))
end

@testset "topoplot: GridLayout" begin
    f = Makie.Figure()
    plot_topoplot!(f[1, 1], dat[:, 150, 1]; positions = positions)
    f
end

@testset "topoplot: labels" begin
    labels = ["s$i" for i = 1:size(dat[:, 150, 1], 1)]
    plot_topoplot(
        dat[:, 150, 1],
        positions = positions;
        labels = labels,
        visual = (; label_text = true),
    )
end

@testset "topoplot: GridSubposition" begin
    f = Makie.Figure()
    plot_topoplot!(
        f[1, 1][1, 1],
        data_for_topoplot;
        positions = rand(Point2f, 10),
        labels = string.(1:10),
    )
    f
end

@testset "topoplot: positions through labels" begin
    plot_topoplot(
        dat[1:19, 50, 1];
        labels = TopoPlots.CHANNELS_10_20,
        visual = (; label_text = true),
    )
end

@testset "topoplot: change interpolation" begin
    plot_topoplot(
        dat[:, 320, 1];
        positions = positions,
        topo_attributes = (; interpolation = DelaunayMesh()),
    )
end


@testset "topoplot: change interpolation" begin
    plot_topoplot(
        dat[:, 320, 1];
        positions = positions,
        topo_attributes = (; interpolation = NullInterpolator()),
    )
end


@testset "topoplot: change aspect" begin
    plot_topoplot(dat[:, 320, 1]; positions = positions, topo_axis = (; aspect = 2))
end

@testset "topoplot: observable" begin
    dat_obs = Observable(dat[:, 320, 1])
    plot_topoplot(dat_obs; positions = positions)
    dat_obs[] = dat[:, 30, 1]
    plot_topoplot(dat_obs; positions = positions)
end


@testset "topoplot: horizontal colorbar" begin
    plot_topoplot(
        dat[:, 50, 1];
        positions,
        colorbar = (; vertical = false, width = 180, label = "Voltage estimate"),
        axis = (; xlabel = "50 ms"),
    )
end

@testset "topoplot: std errors" begin
    f = Figure()
    plot_topoplot!(
        f[:, 1],
        dat[:, 50, 1];
        positions,
        colorbar = (; vertical = false, width = 180, label = "Voltage estimate"),
        axis = (; xlabel = "50 ms"),
    )
    plot_topoplot!(
        f[:, 2],
        dat[:, 50, 2];
        positions,
        colorbar = (; vertical = false, width = 180, label = "Voltage uncertainty"),
        axis = (; xlabel = "50 ms"),
        visual = (; colormap = :viridis),
    )
    colgap!(f.layout, 0)
    f
end

@testset "topoplot: shared colorbars" begin
    data_1, positions = TopoPlots.example_data()
    data_2 = data_1 .* 100
    min, max = minimum(data_2[:, 5, 1]), maximum(data_2[:, 5, 1])

    f = Figure()
    plot_topoplot!(
        f[1, 1],
        data_1[:, 5, 1],
        positions = positions,
        visual = (; limits = (min, max)),
        layout = (; use_colorbar = false),
    ) # how to increase the gap?
    plot_topoplot!(
        f[1, 2],
        data_2[:, 5, 1],
        positions = positions,
        visual = (; limits = (min, max)),
    )
    f
end

@testset "topoplot: markers as random arrows" begin
    random_rotations = rand(64) .* 2π
    plot_topoplot(
        dat[:, 50, 1];
        positions,
        axis = (; xlabel = "50 ms"),
        topo_attributes = (;
            label_scatter = (;
                markersize = 20,
                marker = '↑',
                color = :black,
                rotation = random_rotations,
            )
        ),
    )
end

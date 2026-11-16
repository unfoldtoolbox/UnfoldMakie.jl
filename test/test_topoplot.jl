dat, positions = TopoPlots.example_data()
tp = 340
data_for_topoplot = UnfoldMakie.eeg_array_to_dataframe(rand(10)')

@testset "eeg_topoplot: colorbar" begin
    f, a, h = TopoPlots.eeg_topoplot(1:10, positions = rand(Point2f, 10))
    Colorbar(f[1, 2], h)
    f
end

@testset "topoplot: basic" begin
    plot_topoplot(dat[:, tp, 1]; positions)
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

@testset "topoplot: no legend" begin
    plot_topoplot(dat[:, tp, 1]; positions = positions, layout = (; use_colorbar = false))
end

@testset "topoplot: xlabel" begin
    plot_topoplot(dat[:, tp, 1]; positions = positions, axis = (; xlabel = "[$tp ms]"))
end

@testset "topoplot: GridLayout" begin
    f = Makie.Figure()
    plot_topoplot!(f[1, 1], dat[:, tp, 1]; positions = positions)
    f
end

@testset "topoplot: labels" begin
    labels = ["s$i" for i = 1:size(dat[:, tp, 1], 1)]
    plot_topoplot(
        dat[:, tp, 1],
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
        dat[1:19, tp, 1];
        labels = TopoPlots.CHANNELS_10_20,
        visual = (; label_text = true),
    )
end

@testset "topoplot: change interpolation" begin
    plot_topoplot(
        dat[:, tp, 1];
        positions = positions,
        topo_attributes = (; interpolation = DelaunayMesh()),
    )
end


@testset "topoplot: change interpolation" begin
    plot_topoplot(
        dat[:, tp, 1];
        positions = positions,
        topo_attributes = (; interpolation = NullInterpolator()),
    )
end


@testset "topoplot: change aspect" begin
    plot_topoplot(dat[:, tp, 1]; positions = positions, topo_axis = (; aspect = 2))
end

@testset "topoplot: observable" begin
    dat_obs = Observable(dat[:, tp, 1])
    plot_topoplot(dat_obs; positions = positions)
    dat_obs[] = dat[:, tp, 1]
    plot_topoplot(dat_obs; positions = positions)
end


@testset "topoplot: horizontal colorbar" begin
    plot_topoplot(
        dat[:, tp, 1];
        positions,
        colorbar = (; vertical = false, width = 180),
        axis = (; xlabel = ""),
    )
end

@testset "topoplot: colorbar position" begin
    f = Figure()

    plot_topoplot!(f[1, 1], dat[:, tp, 1]; positions, colorbar = (; labelrotation = π/2, flipaxis = false, position = :left))
    plot_topoplot!(f[1, 2], dat[:, tp, 1]; positions, colorbar = (; position = :right))
    plot_topoplot!(f[2, 1], dat[:, tp, 1]; positions, colorbar = (; width = 140, flipaxis = true, position = :top, vertical = false))
    plot_topoplot!(f[2, 2], dat[:, tp, 1]; positions, colorbar = (; width = 140, flipaxis = false, position = :bottom, vertical = false))
    colsize!(f.layout, 1, Fixed(200))  
    f
end


@testset "topoplot: colorbar limits and colorrange blocked" begin
    msg = "Topoplot uses a shared color range between the plot and colorbar. " *
          "Set `visual = (; colorrange = (lo, hi))` (or `visual = (; limits = ...)`) " *
          "instead of `colorbar = (; limits/colorrange = ...)`."
    @test_throws ErrorException(msg) plot_topoplot(
        dat[:, tp, 1];
        positions,
        colorbar = (; limits = (-1, 1)),
    )

    @test_throws ErrorException(msg) plot_topoplot(
        dat[:, tp, 1];
        positions,
        colorbar = (; colorrange = (-1, 1)),
    )
end

@testset "topoplot: colorrange modes" begin
    vals = Float32[-8, -3, -1, 0, 2, 5, 9, 15]

    default_range = UnfoldMakie.topo_shared_range(vals, (;))
    diverging_range = UnfoldMakie.topo_shared_range(vals, (; colorrange_mode = :diverging_balanced))
    p01, p99 = quantile(vals, [0.01, 0.99])
    balanced_max = Float32(max(abs(p01), abs(p99)))
    @test default_range == diverging_range
    @test diverging_range == (-balanced_max, balanced_max)

    sequential_range = UnfoldMakie.topo_shared_range(vals, (; colorrange_mode = :sequential))
    @test sequential_range == Tuple(Float32.(quantile(vals, [0.05, 0.95])))

    sequential_visual = UnfoldMakie.topo_resolved_visual((;
        colorrange_mode = :sequential,
        colormap = :plasma,
        contours = false,
    ))
    @test sequential_visual.colormap == :plasma
    @test !haskey(sequential_visual, :colorrange_mode)

    default_sequential_visual = UnfoldMakie.topo_resolved_visual((;
        colorrange_mode = :sequential,
        colormap = UnfoldMakie.topo_default_diverging_colormap(),
        contours = false,
    ))
    @test default_sequential_visual.colormap == UnfoldMakie.topo_sequential_colormap()
    @test !haskey(default_sequential_visual, :colorrange_mode)

    plot_topoplot(
        vals;
        positions = rand(Point2f, length(vals)),
        visual = (; colorrange_mode = :sequential),
    )
end

@testset "topoplot: std errors" begin
    f = Figure()
    plot_topoplot!(
        f[:, 1],
        dat[:, tp, 1];
        positions,
        colorbar = (; vertical = false, width = 180),
        axis = (; xlabel = ""),
    )
    plot_topoplot!(
        f[:, 2],
        dat[:, tp, 2];
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
    _min, _max = minimum(data_2[:, 5, 1]), maximum(data_2[:, 5, 1])

    f = Figure()
    plot_topoplot!(
        f[1, 1],
        data_1[:, 5, 1],
        positions = positions,
        visual = (; limits = (_min, _max)),
        layout = (; use_colorbar = false),
    ) # how to increase the gap?
    plot_topoplot!(
        f[1, 2],
        data_2[:, 5, 1],
        positions = positions,
        visual = (; limits = (_min, _max)),
    )
    f
end

@testset "topoplot: markers as random arrows" begin
    random_rotations = rand(64) .* 2π
    plot_topoplot(
        dat[:, tp, 1];
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

@testset "topoplot: categorical color" begin
    plot_topoplot(dat[:, tp, 1]; positions, visual = (; colormap = cgrad(:managua, 10; categorical = true, rev = true)))
end

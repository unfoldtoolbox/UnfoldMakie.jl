eeg_data_matrix, positions = TopoPlots.example_data()
tp = 340
eeg_data_df = UnfoldMakie.eeg_array_to_dataframe(rand(10)')

@testset "eeg_topoplot: colorbar" begin
    f, a, h = TopoPlots.eeg_topoplot(1:10, positions = rand(Point2f, 10))
    Colorbar(f[1, 2], h)
    f
end

@testset "topoplot: basic" begin
    plot_topoplot(eeg_data_matrix[:, tp, 1]; positions)
end

@testset "topoplot: data input as DataFrame" begin
    plot_topoplot(
        eeg_data_df;
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

@testset "topoplot: without colorbar" begin
    plot_topoplot(eeg_data_matrix[:, tp, 1]; positions = positions, layout = (; use_colorbar = false))
end

@testset "topoplot: return objects" begin
    objects = plot_topoplot(
        eeg_data_matrix[:, tp, 1];
        positions,
        return_objects = true,
    )
    @test objects.figure isa Figure
    @test objects.axis isa Axis
    @test objects.topo_axis isa Axis
    @test objects.axis === objects.topo_axis
    @test objects.colorbar isa Colorbar
end

# prevents layout regression
@testset "topoplot: no extra axis space with left colorbar" begin
    f = Figure(size = (520, 240))
    objects = plot_topoplot!(
        f[1, 1],
        eeg_data_matrix[:, tp, 1];
        positions,
        topo_axis = (; width = 250, height = 190),
        topo_attributes = (;
            interpolation = TopoPlots.NullInterpolator(),
        ),
        visual = (;
            contours = false,
        ),
        colorbar = (;
            position = :left,
            vertical = true,
            height = 180,
        ),
        return_objects = true,
    )

    topo_bbox = objects.topo_axis.layoutobservables.computedbbox[]
    colorbar_bbox = objects.colorbar.layoutobservables.computedbbox[]

    # A redundant wrapper axis would reserve space and shift the visible topoplot.
    @test count(content -> content isa Axis, f.content) == 1

    # The layout must preserve the explicitly requested topoplot dimensions.
    @test topo_bbox.widths ≈ Vec2f(250, 190)

    # The colorbar's right edge must stay left of the topoplot's left edge.
    @test colorbar_bbox.origin[1] + colorbar_bbox.widths[1] <= topo_bbox.origin[1]
end

@testset "topoplot: xlabel" begin
    plot_topoplot(eeg_data_matrix[:, tp, 1]; positions = positions, axis = (; xlabel = "[$tp ms]"))
end

@testset "topoplot: GridPosition" begin
    f = Makie.Figure()
    plot_topoplot!(f[1, 1], eeg_data_matrix[:, tp, 1]; positions = positions)
    f
end

@testset "topoplot: channel labels" begin
    labels = ["s$i" for i = 1:size(eeg_data_matrix[:, tp, 1], 1)]
    plot_topoplot(
        eeg_data_matrix[:, tp, 1],
        positions = positions;
        labels = labels,
        visual = (; label_text = true),
    )
end

@testset "topoplot: GridSubposition" begin
    f = Makie.Figure()
    plot_topoplot!(
        f[1, 1][1, 1],
        eeg_data_df;
        positions = rand(Point2f, 10),
        labels = string.(1:10),
    )
    f
end

@testset "topoplot: infer positions from labels" begin
    plot_topoplot(
        eeg_data_matrix[1:19, tp, 1];
        labels = TopoPlots.CHANNELS_10_20,
        visual = (; label_text = true),
    )
end

@testset "topoplot: Delaunay interpolation" begin
    plot_topoplot(
        eeg_data_matrix[:, tp, 1];
        positions = positions,
        topo_attributes = (; interpolation = DelaunayMesh()),
    )
end


@testset "topoplot: no interpolation" begin
    plot_topoplot(
        eeg_data_matrix[:, tp, 1];
        positions = positions,
        topo_attributes = (; interpolation = NullInterpolator()),
    )
end


@testset "topoplot: custom axis aspect" begin
    plot_topoplot(eeg_data_matrix[:, tp, 1]; positions = positions, topo_axis = (; aspect = 2))
end

@testset "topoplot: Observable input and update" begin
    dat_obs = Observable(eeg_data_matrix[:, tp, 1])
    plot_topoplot(dat_obs; positions = positions)
    dat_obs[] = eeg_data_matrix[:, tp, 1]
    plot_topoplot(dat_obs; positions = positions)
end


@testset "topoplot: horizontal colorbar" begin
    plot_topoplot(
        eeg_data_matrix[:, tp, 1];
        positions,
        colorbar = (; vertical = false, width = 180),
        axis = (; xlabel = ""),
    )
end

@testset "topoplot: colorbar positions" begin
    f = Figure()

    plot_topoplot!(f[1, 1], eeg_data_matrix[:, tp, 1]; positions, colorbar = (; labelrotation = π/2, flipaxis = false, position = :left))
    plot_topoplot!(f[1, 2], eeg_data_matrix[:, tp, 1]; positions, colorbar = (; position = :right))
    plot_topoplot!(f[2, 1], eeg_data_matrix[:, tp, 1]; positions, colorbar = (; width = 140, flipaxis = true, position = :top, vertical = false))
    plot_topoplot!(f[2, 2], eeg_data_matrix[:, tp, 1]; positions, colorbar = (; width = 140, flipaxis = false, position = :bottom, vertical = false))
    colsize!(f.layout, 1, Fixed(200))  
    f
end


@testset "topoplot: reject colorbar limits and colorrange" begin
    msg = "Topoplot uses a shared color range between the plot and colorbar. " *
          "Set `visual = (; colorrange = (lo, hi))` (or `visual = (; limits = ...)`) " *
          "instead of `colorbar = (; limits/colorrange = ...)`."
    @test_throws ErrorException(msg) plot_topoplot(
        eeg_data_matrix[:, tp, 1];
        positions,
        colorbar = (; limits = (-1, 1)),
    )

    @test_throws ErrorException(msg) plot_topoplot(
        eeg_data_matrix[:, tp, 1];
        positions,
        colorbar = (; colorrange = (-1, 1)),
    )
end

@testset "topoplot: standard-error plot" begin
    f = Figure()
    plot_topoplot!(
        f[:, 1],
        eeg_data_matrix[:, tp, 1];
        positions,
        colorbar = (; vertical = false, width = 180),
        axis = (; xlabel = ""),
    )
    plot_topoplot!(
        f[:, 2],
        eeg_data_matrix[:, tp, 2];
        positions,
        colorbar = (; vertical = false, width = 180, label = "Voltage uncertainty"),
        axis = (; xlabel = "50 ms"),
        visual = (; colormap = :viridis),
    )
    colgap!(f.layout, 0)
    f
end

@testset "topoplot: shared color range with one colorbar" begin
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

@testset "topoplot: randomly rotated arrow markers" begin
    random_rotations = rand(64) .* 2π
    plot_topoplot(
        eeg_data_matrix[:, tp, 1];
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

@testset "topoplot: categorical colormap" begin
    plot_topoplot(eeg_data_matrix[:, tp, 1]; positions, visual = (; colormap = cgrad(:managua, 10; categorical = true, rev = true)))
end

@testset "montage: get_montage default" begin
    m = UnfoldMakie.get_montage()
    @test length(m.labels) == length(m.positions)
    i = findfirst(==("Cz"), m.labels)
    @test isapprox(m.positions[i][1], 0; atol = 1e-3)
    @test isapprox(m.positions[i][2], 0; atol = 1e-3)
end

@testset "montage: standard_positions" begin
    pos = UnfoldMakie.standard_positions(["Cz", "Fpz", "Oz"])
    @test length(pos) == 3
    @test_throws ErrorException UnfoldMakie.standard_positions(["NotARealElectrode"])
end

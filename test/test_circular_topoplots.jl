#include("setup.jl")
dat, pos = TopoPlots.example_data()
#dat = dat[:, 240, 1]
df = DataFrame(
    :estimate => eachcol(Float64.(dat[:, 100:40:300, 1])),
    :circularVariable => [0, 50, 80, 120, 180, 210],
    :time => 100:40:300,
)
labels = ["s$i" for i = 1:size(dat, 1)]
df = flatten(df, :estimate)

d_topo, positions = UnfoldMakie.example_data("TopoPlots.jl")

@testset "error cases and warns" begin
    @testset "out of error bounds" begin
        testdf = DataFrame(
            estimate = [[4.0, 1.0], [4.0, 3.0], [4.0, 3.0]],
            predictor = [70, 80, 400],
        )

        @test_throws ErrorException plot_circular_topoplots(
            testdf;
            positions = [Point(1.0, 2.0), Point(1.0, 2.0), Point(1.0, 2.0)],
        )
    end

    @testset "Too Many BoundsErr" begin
        testdf = DataFrame(
            estimate = [[4.0, 1.0], [4.0, 3.0], [4.0, 3.0]],
            predictor = [70, 80, 90],
        )

        @test_throws ErrorException plot_circular_topoplots(
            testdf;
            predictor_bounds = [0, 100, 360],
            positions = [Point(1.0, 2.0), Point(1.0, 2.0), Point(1.0, 2.0)],
        )
    end
end

@testset "testing calculate_global_max_values" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    pred = repeat(1:3, inner = 5)
    val = [1:5...; 6:10...; 11:15...]
    a, b = UnfoldMakie.calculate_global_max_values(val, pred)
    @test isapprox(a, -14.96)
    @test isapprox(b, 14.96)

end

@testset "testing calculate_axis_labels" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    @test UnfoldMakie.calculate_axis_labels([0, 360]) == ["0", "90", "180 ", "270"]
    @test UnfoldMakie.calculate_axis_labels([-180, 180]) == ["-180", "-90", "0 ", "90"]
    @test UnfoldMakie.calculate_axis_labels([0, 100]) == ["0", "25", "50 ", "75"]
end

@testset "testing calculate_BBox" begin
    @test UnfoldMakie.calculate_BBox([0, 0], [1000, 1000], 180, [0, 360], 0.8) ==
          BBox(0.0, 200.0, 400.0, 600)
    @test UnfoldMakie.calculate_BBox([0, 0], [1000, 1000], -45, [0, 360], 0.8) ==
          BBox(682.842712474619, 882.842712474619, 117.15728752538104, 317.15728752538104)
    @test UnfoldMakie.calculate_BBox([0, 0], [1000, 1000], -180, [-180, 180], 0.8) ==
          BBox(800.0, 1000.0, 400.0, 600.0)
end

@testset "circularplot plot basic" begin
    plot_circular_topoplots(
        df;
        positions = pos,
        center_label = "Visual angle [°]",
        predictor = :time,
        predictor_bounds = [80, 320],
    )
end

@testset "circularplot plot in GridLayout with labels" begin
    f = Figure()
    ga = f[1, 1] = GridLayout()
    plot_circular_topoplots!(
        ga,
        df;
        positions = pos,
        center_label = "Visual angle [°]",
        predictor = :time,
        predictor_bounds = [80, 320],
        labels = labels,
    )
    f
end

@testset "circularplot plot basic" begin
    plot_circular_topoplots(
        d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
        positions = positions,
        predictor = :time,
        predictor_bounds = [-0.3, 0.5],
    )
end

@testset "circularplot plot in GridLayout" begin
    f = Figure(size = (2000, 2000))
    plot_circular_topoplots!(
        f[3:4, 4:5],
        d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
        positions = positions,
        predictor = :time,
        predictor_bounds = [-0.3, 0.5],
    )
    f
end

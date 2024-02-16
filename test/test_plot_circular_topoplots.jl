#include("setup.jl")

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

    @testset "tooManyBoundsErr" begin
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

@testset "testing calculateGlobalMaxValues" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    pred = repeat(1:3, inner = 5)
    val = [1:5...; 6:10...; 11:15...]
    a, b = UnfoldMakie.calculateGlobalMaxValues(val, pred)
    @test isapprox(a, -14.96)
    @test isapprox(b, 14.96)

end

@testset "testing calculateAxisLabels" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    @test UnfoldMakie.calculateAxisLabels([0, 360]) == ["0", "90", "180   ", "270"]
    @test UnfoldMakie.calculateAxisLabels([-180, 180]) == ["-180", "-90", "0   ", "90"]
    @test UnfoldMakie.calculateAxisLabels([0, 100]) == ["0", "25", "50   ", "75"]
end

@testset "testing calculateBBox" begin
    @test UnfoldMakie.calculateBBox([0, 0], [1000, 1000], 180, [0, 360]) ==
          BBox(50.0, 250.0, 400.0, 600.0)
    @test UnfoldMakie.calculateBBox([0, 0], [1000, 1000], -45, [0, 360]) ==
          BBox(647.48737, 847.48737, 152.51262, 352.51262)
    @test UnfoldMakie.calculateBBox([0, 0], [1000, 1000], -180, [-180, 180]) ==
          BBox(750.0, 950.0, 400.0, 600.0)
end

@testset "circularplot plot in GridLayout" begin
    f = Figure(resolution = (1200, 1400))
    data, pos = TopoPlots.example_data()
    dat = data[:, 240, 1]
    df = DataFrame(
        :estimate => eachcol(Float64.(data[:, 100:40:300, 1])),
        :circularVariable => [0, 50, 80, 120, 180, 210],
        :time => 100:40:300,
    )
    df = flatten(df, :estimate)
    ga = f[1, 1] = GridLayout()
    plot_circular_topoplots!(
        ga,
        df;
        positions = pos,
        axis = (; label = "Time?!"),
        predictor = :time,
        predictor_bounds = [80, 320],
    )
    f
end

@testset "circularplot plot in GridLayout" begin
    d_topo, positions = example_data("TopoPlots.jl")
    f = Figure(resolution = (2000, 2000))
    plot_circular_topoplots!(
        f[3:4, 4:5],
        d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
        positions = positions,
        predictor = :time,
        predictor_bounds = [-0.3, 0.5],
    )
    f
end

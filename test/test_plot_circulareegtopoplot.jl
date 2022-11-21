@testset "error cases and warns" begin
    let outOfBoundsErr = nothing
        testdf = DataFrame(
            effect=[[4.0, 1.0], [4.0, 3.0], [4.0, 3.0]],
            predictor=[70, 80, 400],
            positions=[Point(1.0, 2.0), Point(1.0, 2.0), Point(1.0, 2.0)],
        )

        try
            plot_circulareegtopoplot(testdf)
        catch outOfBoundsErr
        end

        @test outOfBoundsErr isa Exception
        @test sprint(showerror, outOfBoundsErr) == "all values in the plotData's effect column have to be within the config.extraData.predictorBounds range"
    end

    let tooManyBoundsErr
        testdf = DataFrame(
            effect=[[4.0, 1.0], [4.0, 3.0], [4.0, 3.0]],
            predictor=[70, 80, 90],
            positions=[Point(1.0, 2.0), Point(1.0, 2.0), Point(1.0, 2.0)],
        )

        try
            config = PlotConfig(:circeegtopo).setExtraValues!(predictorBounds=[0, 100, 360])
            plot_circulareegtopoplot(testdf, config)
        catch tooManyBoundsErr
        end

        @test tooManyBoundsErr isa Exception
        @test sprint(showerror, tooManyBoundsErr) == "config.extraData.predictorBounds needs exactly two values"
    end

    triggerwarndf = DataFrame(
        effect=[[4.0, 1.0, 2.0], [4.0, 3.0, 2.0], [4.0, 3.0, 2.0]],
        predictor=[pi, 1 / 2 * pi, 1 / 4 * pi],
        positions=[[Point(1.0, 3.0), Point(2.0, 2.0), Point(9.0, 1.0)], [Point(1.0, 3.0), Point(2.0, 2.0), Point(9.0, 1.0)], [Point(1.0, 3.0), Point(2.0, 2.0), Point(9.0, 1.0)]],
    )

    plot_circulareegtopoplot(triggerwarndf)
    @test_logs (:warn, "you have been warned")
end

@testset "testing calculateGlobalMaxValues" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    @test calculateGlobalMaxValues([[1, 2], [3, 4], [5, 6, 7], [8], [9, 10]]) == (-9.99, 9.99)
    @test calculateGlobalMaxValues([[-1, -2], [-3, -4], [5, 6, 7], [-8], [9, 10]]) == (-9.99, 9.99)
end

@testset "testing calculateAxisLabels" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    @test calculateAxisLabels([0, 360]) == ["0", "90", "180   ", "270"]
    @test calculateAxisLabels([-180, 180]) == ["-180", "-90", "0   ", "90"]
    @test calculateAxisLabels([0, 100]) == ["0", "25", "50   ", "75"]
end

@testset "testing calculateBBox" begin
    @test calculateBBox([0, 0], [1000, 1000], 180, [0, 360]) == BBox(50.0, 250.0, 400.0, 600.0)
    @test calculateBBox([0, 0], [1000, 1000], -45, [0, 360]) == BBox(647.48737, 847.48737, 152.51262, 352.51262)
    @test calculateBBox([0, 0], [1000, 1000], -180, [-180, 180]) == BBox(750.0, 950.0, 400.0, 600.0)
end


#include("setup.jl")

@testset "error cases and warns" begin
    
    @testset "out of error bounds" begin
        testdf = DataFrame(
            estimate = [[4.0,1.0],[4.0,3.0],[4.0,3.0]],
            predictor = [70,80,400],
            
        )
        
    @test_throws ErrorException plot_circulareegtopoplot(testdf;positions=[Point(1.0,2.0), Point(1.0,2.0), Point(1.0,2.0)],)
    end

    @testset "tooManyBoundsErr" begin
        testdf = DataFrame(
            estimate = [[4.0,1.0],[4.0,3.0],[4.0,3.0]],
            predictor = [70,80,90],
            )
            
            @test_throws ErrorException plot_circulareegtopoplot(testdf;   extra=(;predictorBounds=[0,100,360]),          positions = [Point(1.0,2.0), Point(1.0,2.0), Point(1.0,2.0)],)

    end
end



@testset "testing calculateGlobalMaxValues" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    pred =repeat(1:3,inner=5)
    val = [1:5...; 6:10...; 11:15...]
    @test UnfoldMakie.calculateGlobalMaxValues(val,pred) == (-14.96, 14.96)
    
end

@testset "testing calculateAxisLabels" begin
    # notice: this function uses the 0.01 and the 0.99 quantile
    @test UnfoldMakie.calculateAxisLabels([0, 360]) == ["0", "90", "180   ", "270"]
    @test UnfoldMakie.calculateAxisLabels([-180, 180]) == ["-180", "-90", "0   ", "90"]
    @test UnfoldMakie.calculateAxisLabels([0, 100]) == ["0", "25", "50   ", "75"]
end

@testset "testing calculateBBox" begin
    @test UnfoldMakie.calculateBBox([0, 0], [1000, 1000], 180, [0, 360]) == BBox(50.0, 250.0, 400.0, 600.0)
    @test UnfoldMakie.calculateBBox([0, 0], [1000, 1000], -45, [0, 360]) == BBox(647.48737, 847.48737, 152.51262, 352.51262)
    @test UnfoldMakie.calculateBBox([0, 0], [1000, 1000], -180, [-180, 180]) == BBox(750.0, 950.0, 400.0, 600.0)
end


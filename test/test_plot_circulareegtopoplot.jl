@testset "error cases and warns" begin
    
    let outOfBoundsErr = nothing 
        testdf = DataFrame(
            effect = [[4.0,1.0],[4.0,3.0],[4.0,3.0]],
            predictor = [70,80,400],
            positions = [Point(1.0,2.0), Point(1.0,2.0), Point(1.0,2.0)],
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
            effect = [[4.0,1.0],[4.0,3.0],[4.0,3.0]],
            predictor = [70,80,90],
            positions = [Point(1.0,2.0), Point(1.0,2.0), Point(1.0,2.0)],
        )

        try
            config = PlotConfig(:circeegtopo).setExtraValues!(predictorBounds = [0, 100, 360])
            plot_circulareegtopoplot(testdf, config)
        catch tooManyBoundsErr
        end

        @test tooManyBoundsErr isa Exception
        @test sprint(showerror, tooManyBoundsErr) == "config.extraData.predictorBounds needs exactly two values"
    end
end
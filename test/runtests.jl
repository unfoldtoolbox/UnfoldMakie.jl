using UnfoldMakie
include("setup.jl")
#include("../src/UnfoldMakie.jl")


@testset "Test Config" begin
    include("test_config.jl")
end
@testset "CircularEEGTopoPlot" begin
    include("test_plot_circulareegtopoplot.jl")
end

@testset "TopoSeries" begin
    include("test_toposeries.jl")
end

@testset "ERPImage" begin
    include("test_erpimage.jl")
end

@testset "TopoPlot" begin
    include("test_topoplot.jl")
end

@testset "Butterfly" begin
    include("test_butterfly.jl")
end

@testset "AllPlots" begin
    include("test_all.jl")
end

include("../docs/example_data.jl")
data, pos = example_data("TopoPlots.jl")
using Colors

@testset "basic" begin
    plot_butterfly(data; positions = pos)
end

@testset "topomarkersize change" begin
    plot_butterfly(
        data;
        positions = pos,
        topomarkersize = 10,
        topoheigth = 0.4,
        topowidth = 0.4,
    )
end

@testset "changing color from ROMA to gray" begin
    plot_butterfly(
        data;
        positions = pos,
        topopositions_to_color = x -> Colors.RGB(0.5)
    )
end

@testset "changing color from ROMA to HSV" begin
    plot_butterfly(
        data;
        positions = pos,
        topopositions_to_color=UnfoldMakie.posToColorHSV
    )
end

@testset "changing color from ROMA to RGB" begin
    plot_butterfly(
        data;
        positions = pos,
        topopositions_to_color = pos -> UnfoldMakie.posToColorRGB(pos)
    )
end

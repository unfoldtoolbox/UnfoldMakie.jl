include("setup.jl")
@testset "markersize change" begin
    include("example_data.jl")
    data, pos = example_data("TopoPlots.jl")
    plot_butterfly(data; positions=pos, extra=(markersize = 10, topoheigth=0.4, topowidth=0.4))
end

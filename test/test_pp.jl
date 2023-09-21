
@testset "markersize change" begin
    include("../docs/example_data.jl")
    results_plot, positions = example_data();
    plot_parallelcoordinates(results_plot, [5,3,2]; # this selects channel 5,3 & 2 
        mapping = (color = :coefname, y = :estimate))
end

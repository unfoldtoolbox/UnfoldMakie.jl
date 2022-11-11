using Test
include("../src/UnfoldMakie.jl")

@testset "UnfoldMakie.jl" begin
    include("test_plot_circulareegtopoplot.jl")
end
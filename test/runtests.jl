
include("setup.jl")
#include("../src/UnfoldMakie.jl")

@testset "UnfoldMakie.jl" begin
    include("test_plot_circulareegtopoplot.jl")
end

@testset "UnfoldMakie.jl" begin
    include("test_toposeries.jl")
end

@testset "UnfoldMakie.jl" begin
    include("test_erpimage.jl")
end


@testset "UnfoldMakie.jl" begin
    include("test_topoplot.jl")
end
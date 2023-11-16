using UnfoldMakie
include("setup.jl")
#include("../src/UnfoldMakie.jl")


@testset "Test Config" begin
    include("test_config.jl")
end

@testset "ERP plot" begin
    include("test_erp.jl")
end

@testset "Butterfly" begin
    include("test_butterfly.jl")
end

@testset "ERP Image" begin
    include("test_erpimage.jl")
end

@testset "Topoplot" begin
    include("test_topoplot.jl")
end

@testset "Topoplot series" begin
    include("test_toposeries.jl")
end

@testset "Parallel coordinates plot" begin
    include("test_pcp.jl")
end

@testset "Circular EEG topoplot" begin
    include("test_plot_circulareegtopoplot.jl")
end

@testset "Complex plots" begin
    include("test_complexplots.jl")
end
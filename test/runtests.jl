using UnfoldMakie
include("setup.jl")
#include("../src/UnfoldMakie.jl")

@testset "Test Config" begin
    include("test_config.jl")
end

@testset "ERP plot" begin
    include("test_erp.jl")
end

@testset "ERP plot: effects" begin
    include("test_erp_effects.jl")
end

@testset "Butterfly" begin
    include("test_butterfly.jl")
end

@testset "ERP image" begin
    include("test_erpimage.jl")
end

@testset "Channel image" begin
    include("test_channelimage.jl")
end

@testset "Topoplot" begin
    include("test_topoplot.jl")
end

@testset "Topoplot series simple" begin
    include("test_toposeries1.jl")
end

@testset "Topoplot series advanced" begin
    include("test_toposeries2.jl")
end

@testset "ERP grid" begin
    include("test_erpgrid.jl")
end

@testset "Parallel coordinates" begin
    include("test_pcp.jl")
end

@testset "Circular EEG topoplot" begin
    include("test_circular_topoplots.jl")
end

@testset "Design matricies" begin
    include("test_dm.jl")
end

@testset "Spline plots" begin
    include("test_splines.jl")
end

@testset "Complex plots" begin
    include("test_complexplots.jl")
end

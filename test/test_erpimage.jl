include("setup.jl")
@testset "testing calculateBBox" begin
    data, evts = UnfoldSim.predef_eeg(;noiselevel=10, return_epoched=true)
    plot_erpimage(data; ploterp = false,)
end

@testset "testing calculateBBox" begin
    data, evts = UnfoldSim.predef_eeg(;noiselevel=10, return_epoched=true)
    plot_erpimage(data; ploterp = true,)
end

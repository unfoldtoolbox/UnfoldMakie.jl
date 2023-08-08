#include("setup.jl")
@testset "testing no bottom erp plot" begin
    data, evts = UnfoldSim.predef_eeg(;noiselevel=10, return_epoched=true)
    plot_erpimage(data; ploterp = false,)
end

@testset "testing with bottom erp plot" begin
    data, evts = UnfoldSim.predef_eeg(;noiselevel=10, return_epoched=true)
    plot_erpimage(data; ploterp = true,)
end

@testset "testing no bottom erp plot in extra mode" begin
    data, evts = UnfoldSim.predef_eeg(;noiselevel=10, return_epoched=true)
    plot_erpimage(data; extra = (ploterp = true,),)
end

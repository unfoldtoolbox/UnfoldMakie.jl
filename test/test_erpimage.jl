#include("setup.jl")
@testset "basic" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data;)
end

@testset "with mean erp plot" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data; meanplot = true)
end

@testset "changing erpblur to zero" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data; meanplot = true, erpblur = 0)
end

@testset "GridPosition" begin
    f = Figure()
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage!(f[1, 1], data; meanplot = true)
    #save("erpimage.eps", f)
end

@testset "testing better sorting" begin
    using UnfoldSim
    dat, evts =
        UnfoldSim.predef_eeg(; onset = LogNormalOnset(μ = 3.5, σ = 0.4), noiselevel = 5)
    dat_e, times = Unfold.epoch(dat, evts, [-0.1, 1], 100)
    evts, dat_e = Unfold.dropMissingEpochs(evts, dat_e)
    evts.Δlatency = diff(vcat(evts.latency, 0))
    dat_e = dat_e[1, :, :]
    plot_erpimage(times, dat_e; sortvalues = evts.Δlatency)
end

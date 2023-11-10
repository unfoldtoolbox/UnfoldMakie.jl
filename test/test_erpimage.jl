#include("setup.jl")
@testset "basic" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data;)
end

@testset "with mean erp plot" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data; meanPlot = true)
end

@testset "changing erpBlur to zero" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data; meanPlot = true, erpBlur = 0)
end

@testset "GridPosition" begin
    f = Figure()
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage!(f[1, 1], data; meanPlot = true)
    #save("erpimage.eps", f)
end


#=
@testset "testing better sorting" begin

    using PyMNE
    using Unfold
    using CSV


    evts = CSV.read("/store/data/WLFO/derivatives/preproc_agert/sub-20/eeg/sub-20_task-WLFO_events.tsv", DataFrame)
    evts.latency = evts.onset .* 512
    evts_fix = subset(evts, :type => x -> x .== "fixation")
    raw = PyMNE.io.read_raw_eeglab("/store/data/WLFO/derivatives/preproc_agert/sub-20/eeg/sub-20_task-WLFO_eeg.set")
    d, times = Unfold.epoch(pyconvert(Array, raw.get_data(units="uV")), evts_fix, (-0.1, 1), 512)
    coalesce.(d[1, :, :], NaN)
    f = Figure()
    d_nan = coalesce.(d[1, :, :], NaN)
    v = (; colorrange=(-10, 10))
    @show size(d_nan)
    plot_erpimage!(f[1, 1], times, d_nan, visual=v)
    plot_erpimage!(f[1, 2], times, d_nan; sortvalues=diff(evts_fix.onset ./ 100), visual=v)
    plot_erpimage!(f[2, 1], times, d_nan; sortvalues=evts_fix.sac_startpos_x, visual=v)
    plot_erpimage!(f[2, 2], times, d_nan; sortvalues=evts_fix.sac_amplitude, visual=v)
    f
end
=#

@testset "ERP image basic" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data;)
end

@testset "ERP image with mean erp plot" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data; meanplot = true)
end

@testset "ERP image with changing erpblur to zero" begin
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage(data; meanplot = true, erpblur = 0)
end

@testset "ERP image with GridPosition" begin
    f = Figure()
    data, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
    plot_erpimage!(f[1, 1], data; meanplot = true)
    #save("erpimage.eps", f)
end

@testset "ERP image with sortvalues" begin
    include("../docs/example_data.jl")
    dat_e, evts, times = example_data("sort_data")    
    #println(describe(evts.Δlatency))
    plot_erpimage(times, dat_e; sortvalues = evts.Δlatency)
end


@testset "ERP image with sortindex" begin
    include("../docs/example_data.jl")
    dat_e, evts, times = example_data("sort_data")    
    #println(describe(evts.Δlatency))
    plot_erpimage(times, dat_e; sortindex = evts.Δlatency)
end
include("../docs/example_data.jl")

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
end

@testset "ERP image with sortvalues" begin
    dat_e, evts, times = example_data("sort_data")
    plot_erpimage(times, dat_e; sortvalues = evts.Δlatency)
end


@testset "ERP image with sortindex" begin
    dat_e, evts, times = example_data("sort_data")
    plot_erpimage(times, dat_e; sortindex = evts.Δlatency)
end

@testset "ERP image normalised" begin
    dat_e, evts, times = example_data("sort_data")
    dat_norm = dat_e[:, :] .- mean(dat_e, dims = 2)
    plot_erpimage(times, dat_norm; sortvalues = evts.Δlatency)
end

@testset "ERP image with and withour sorting" begin
    f = Figure()
    dat_e, evts, times = example_data("sort_data")
    plot_erpimage!(f[1, 1], times, dat_e; axis = (; title = "Bad"))
    plot_erpimage!(
        f[2, 1],
        times,
        dat_e;
        sortvalues = evts.Δlatency,
        axis = (; title = "Good"),
    )
    f
    #save("erpimage.png", f)
end

@testset "ERP image with different labels" begin
    f = Figure()
    dat_e, evts, times = example_data("sort_data")
    dat_norm = dat_e[:, :] .- mean(dat_e, dims = 2)
    plot_erpimage!(f[1, 1], times, dat_e; axis = (; ylabel = "test"))
    plot_erpimage!(
        f[2, 1],
        times,
        dat_e;
        sortvalues = evts.Δlatency,
        axis = (; ylabel = "test"),
    )
    plot_erpimage!(f[1, 2], times, dat_e;)
    plot_erpimage!(f[2, 2], times, dat_e; sortvalues = evts.Δlatency)
    f
end

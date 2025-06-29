dat, evts = UnfoldSim.predef_eeg(; noiselevel = 10, return_epoched = true)
dat_e, evts_e, times = UnfoldMakie.example_data("sort_data")

@testset "ERP image with data matrix" begin
    plot_erpimage(dat)
end

#= @testset "ERP image with data matrix" begin
    plot_erpimage(Resampler(rand(10, 100000)))
end
 =#

@testset "ERP image naked" begin
    f = Figure(; figure_padding = 0)
    plot_erpimage!(
        f,
        dat;
        layout = (; hidespines = (), hidedecorations = (), use_colorbar = false),
    )
end

@testset "ERP image sorted and naked" begin
    f = Figure(; figure_padding = 0)
    plot_erpimage!(
        f,
        dat_e;
        sortvalues = evts_e.Δlatency,
        layout = (; hidespines = (), hidedecorations = (), use_colorbar = false),
    )
end

@testset "ERP image with changing erpblur to zero" begin
    plot_erpimage(dat; erpblur = 0)
end

@testset "ERP image with GridPosition" begin
    f = Figure()
    plot_erpimage!(f[1, 1], dat)
end

@testset "ERP image with sortvalues" begin
    plot_erpimage(times, dat_e; sortvalues = evts_e.Δlatency)
end


@testset "ERP image with sortindex" begin
    plot_erpimage(
        times,
        dat_e;
        sortindex = rand(1:length(evts_e.Δlatency), length(evts_e.Δlatency)),
    )
end

@testset "ERP image normalized" begin
    dat_norm = dat_e[:, :] .- mean(dat_e, dims = 2)
    plot_erpimage(times, dat_norm; sortvalues = evts_e.Δlatency)
end

@testset "ERP image with and without sorting" begin
    f = Figure()
    plot_erpimage!(f[1, 1], times, dat_e; axis = (; title = "Bad"))
    plot_erpimage!(
        f[2, 1],
        times,
        dat_e;
        sortvalues = evts_e.Δlatency,
        axis = (; title = "Good"),
    )
    f
    #save("erpimage.png", f)
end

@testset "ERP image with different labels" begin
    f = Figure()
    dat_norm = dat_e[:, :] .- mean(dat_e, dims = 2)
    plot_erpimage!(f[1, 1], times, dat_e; axis = (; ylabel = "test"))
    plot_erpimage!(
        f[2, 1],
        times,
        dat_e;
        sortvalues = evts_e.Δlatency,
        axis = (; ylabel = "test"),
    )
    plot_erpimage!(f[1, 2], times, dat_norm;)
    plot_erpimage!(f[2, 2], times, dat_norm; sortvalues = evts_e.Δlatency)
    f
end

@testset "ERP image with mean plot" begin
    plot_erpimage(dat; meanplot = true)
end

@testset "ERP image with meanplot and show_sortval" begin
    plot_erpimage(
        times,
        dat_e;
        sortvalues = evts_e.Δlatency,
        meanplot = true,
        show_sortval = true,
    )
end

@testset "ERP image with show_sortval" begin
    dat_e, evts_e, times = UnfoldMakie.example_data("sort_data")
    plot_erpimage(times, dat_e; sortvalues = evts_e.Δlatency, show_sortval = true)
end

@testset "ERP image with Observables" begin
    obs = Observable(dat)
    f = plot_erpimage(obs)
    obs[] = rand(size(to_value(dat))...)
end

@testset "ERP image with Observables and sort_val" begin
    obs = Observable(dat)
    sort_val = Observable(evts_e.Δlatency)
    f = plot_erpimage(times, dat_e; sortvalues = sort_val, show_sortval = true)
    sort_val[] = rand(Int, size(to_value(evts_e.Δlatency))...)
end

@testset "ERP image with Observables and title as Observable" begin
    obs = Observable(dat)
    chan_i = Observable(1)
    sort_val = Observable(evts_e.Δlatency)
    str = @lift("ERP image: channel " * string($chan_i))
    f = plot_erpimage(
        times,
        dat_e;
        sortvalues = sort_val,
        show_sortval = true,
        axis = (; title = str),
    )
    str[] = "TEST"
end

@testset "ERP image with sortval_xlabel" begin
    str = Observable("&&&")
    plot_erpimage(
        times,
        dat_e;
        sortvalues = evts_e.Δlatency,
        meanplot = true,
        show_sortval = true,
        sortval_xlabel = str,
    )
    str[] = "TEST2"
end

@testset "ERP image with sortval_xlabel" begin
    sortval = Observable(evts_e.Δlatency)
    plot_erpimage(times, dat_e; sortvalues = sortval, meanplot = true, show_sortval = true)
    sortval = Observable(evts_e.continuous)
end

@testset "check error of empty sortvalues" begin
    err1 = nothing
    t() = error(plot_erpimage(times, dat_e; show_sortval = true))
    try
        t()
    catch err1
    end

    @test err1 == ErrorException("`show_sortval` needs non-empty `sortvalues` argument")
end

@testset "check error of all NaN sortvalues" begin
    tmp = fill(NaN, size(dat_e, 2))

    err1 = nothing
    t() = error(plot_erpimage(times, dat_e; sortvalues = tmp, show_sortval = true))
    try
        t()
    catch err1
    end

    @test err1 ==
          ErrorException("`show_sortval` can not take `sortvalues` with all NaN-values")
end

@testset "check length mismatch" begin
    tmp = fill(NaN, size(dat_e, 1))

    err1 = nothing
    t() = error(plot_erpimage(times, dat_e; sortvalues = tmp, show_sortval = true))
    try
        t()
    catch err1
    end

    @test err1 == ErrorException(
        "The length of sortvalues differs from the length of data trials. This leads to incorrect sorting.",
    )
end

@testset "ERP image: meanplot axis" begin
    plot_erpimage(dat; meanplot = true, meanplot_axis = (; title = "test"))
end

@testset "ERP image: sortplot axis" begin
    plot_erpimage(
        times,
        dat_e;
        sortvalues = evts_e.Δlatency,
        show_sortval = true,
        sortplot_axis = (; title = "test"),
    )
end

@testset "ERP image with categorical sorting values" begin
    tmp_d = rand(5, 10)
    plot_erpimage(tmp_d, sortvalues = string.(1:10), show_sortval = true)
end

@testset "ERP image with user-setted colorrange" begin
    plot_erpimage(dat, colorbar = (; colorrange = (-0.75, 0.75)))
end

@testset "ERP image: yticklabelsvisible" begin
    plot_erpimage(dat; axis = (; yticklabelsvisible = false))
end

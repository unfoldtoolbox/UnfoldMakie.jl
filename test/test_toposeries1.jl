# simple checks

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
bin_width = 80

@testset "toposeries basic with bin_width" begin
    plot_topoplotseries(df; bin_width, positions = positions)
end

@testset "toposeries basic with bin_num" begin
    plot_topoplotseries(df; bin_num = 5, positions = positions)
end

@testset "toposeries basic with nrows specified" begin
    plot_topoplotseries(df; bin_num = 5, nrows = 2, positions = positions)
end

@testset "toposeries basic with nrows specified" begin
    plot_topoplotseries(df; bin_num = 5, nrows = 3, positions = positions)
end

@testset "toposeries basic with nrows specified" begin
    plot_topoplotseries(df; bin_num = 5, nrows = -6, positions = positions)
end

@testset "error checking: bin_width and bin_num specified" begin
    err1 = nothing
    t() = error(plot_topoplotseries(df; bin_width, bin_num = 5, positions = positions))
    try
        t()
    catch err1
    end
    @test err1 ==
          ErrorException("Ambigious parameters: specify only `bin_width` or `bin_num`.")
end

@testset "error checking: bin_width and bin_num not specified" begin
    err1 = nothing
    t() = error(plot_topoplotseries(df; positions = positions))
    try
        t()
    catch err1
    end
    @test err1 == ErrorException(
        "You haven't specified `bin_width` or `bin_num`. Such option is available only with categorical `mapping.col` or `mapping.row`.",
    )
end

@testset "toposeries basic with channel names" begin
    plot_topoplotseries(df; bin_width, positions = positions, labels = raw_ch_names)
end # doesnt work rn

@testset "toposeries with xlabel" begin
    f = Figure()
    ax = Axis(f[1, 1])
    plot_topoplotseries!(f[1, 1], df; bin_width, positions = positions)
    text!(ax, 0, 0, text = "Time [ms] ", align = (:center, :center), offset = (0, -120))
    hidespines!(ax) # delete unnecessary spines (lines)
    hidedecorations!(ax, label = false)
    f
end

@testset "toposeries for one time point (?)" begin
    plot_topoplotseries(df; bin_width, positions = positions, combinefun = x -> x[end÷2])
end

@testset "toposeries with differend comb functions " begin
    f = Figure(size = (500, 500))
    plot_topoplotseries!(
        f[1, 1],
        df;
        bin_width,
        positions = positions,
        combinefun = mean,
        axis = (; xlabel = "", title = "combinefun = mean"),
    )
    plot_topoplotseries!(
        f[2, 1],
        df;
        bin_width,
        positions = positions,
        combinefun = median,
        axis = (; xlabel = "", title = "combinefun = median"),
    )
    plot_topoplotseries!(
        f[3, 1],
        df;
        bin_width,
        positions = positions,
        combinefun = std,
        axis = (; title = "combinefun = std"),
    )
    f
end

@testset "toposeries without colorbar" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        layout = (; use_colorbar = false),
    )
end

@testset "GridPosition with a title" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")

    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))

    bin_width = 80
    a = plot_topoplotseries!(
        f[1:2, 1:5],
        df;
        bin_width,
        positions = positions,
        layout = (; use_colorbar = true),
    )
    hidespines!(ax)
    hidedecorations!(ax, label = false)

    f
end

@testset "toposeries with specified xlabel" begin
    plot_topoplotseries(df; bin_width, positions = positions, axis = (; xlabel = "test"))
end

@testset "toposeries with adjustable colorrange" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        colorbar = (; colorrange = (-1, 1)),
    )
end

@testset "toposeries with adjusted ylim_topo" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        axis = (; ylim_topo = (0, 0.7)),
    )
end

#= @testset "basic eeg_topoplot_series" begin
    df = DataFrame(
        :erp => repeat(1:63, 100),
        :time => repeat(1:20, 5 * 63),
        :label => repeat(1:63, 100),
    ) # simulated data
    a = (sin.(range(-2 * pi, 2 * pi, 63)))
    b = [(1:63) ./ 63 .* a (1:63) ./ 63 .* cos.(range(-2 * pi, 2 * pi, 63))]
    pos = b .* 0.5 .+ 0.5 # simulated electrode positions
    pos = [Point2.(pos[k, 1], pos[k, 2]) for k = 1:size(pos, 1)]
    UnfoldMakie.eeg_topoplot_series(df; bin_width = 5, positions = pos)
end =#

@testset "toposeries with GridSubposition" begin
    f = Figure(size = (500, 500))
    plot_topoplotseries!(
        f[2, 1][1, 1],
        df;
        bin_width,
        positions = positions,
        combinefun = mean,
        axis = (; title = "combinefun = mean"),
    )
end

# simple checks

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
bin_width = 80

@testset "toposeries with bin_width" begin
    plot_topoplotseries(df; bin_width = 80, positions = positions)
end

@testset "toposeries with bin_num" begin
    plot_topoplotseries(df; bin_num = 5, positions = positions)
end

@testset "toposeries: checking other y value" begin
    df.cont = df.time .* 3
    plot_topoplotseries(df; bin_num = 5, positions = positions, mapping = (; col = :cont))
end

#= @testset "toposeries with Δbin deprecated" begin #fail
    plot_topoplotseries(df, Δbin; positions = positions)
end =#

@testset "toposeries with nrows = 2" begin
    plot_topoplotseries(df; bin_num = 5, nrows = 2, positions = positions)
end

@testset "toposeries with nrows = 5" begin
    plot_topoplotseries(df; bin_num = 5, nrows = 3, positions = positions)
end

@testset "toposeries with nrows = -6" begin
    plot_topoplotseries(df; bin_num = 5, nrows = -6, positions = positions)
end

@testset "error checking: bin_width and bin_num specified" begin
    err1 = nothing
    t() = error(plot_topoplotseries(df; bin_width = 80, bin_num = 5, positions = positions))
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

@testset "toposeries with channel names" begin
    plot_topoplotseries(df; bin_width = 80, positions = positions, labels = raw_ch_names)
end # doesnt work rn

@testset "toposeries with xlabel" begin
    f = Figure()
    ax = Axis(f[1, 1])
    plot_topoplotseries!(f[1, 1], df; bin_width = 80, positions = positions)
    text!(ax, 0, 0, text = "Time [ms] ", align = (:center, :center), offset = (0, -120))
    hidespines!(ax) # delete unnecessary spines (lines)
    hidedecorations!(ax, label = false)
    f
end

@testset "toposeries for one time point (what is it?)" begin
    plot_topoplotseries(
        df;
        bin_width = 80,
        positions = positions,
        combinefun = x -> x[end÷2],
    )
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
        colorbar = (; colorrange = (-3, 3)),
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

@testset "basic eeg_topoplot_series" begin
    df = DataFrame(
        :erp => repeat(1:64, 100),
        :cont_cuts => repeat(1:20, 5 * 64),
        :label => repeat(1:64, 100),
        :col_coord => repeat(1:5, 20 * 64),
        :row_coord => repeat(1:1, 6400),
    ) # simulated data
    UnfoldMakie.eeg_topoplot_series(
        df;
        bin_width = 5,
        positions = positions,
        col = :col_coord,
        row = :row_coord,
    )
end

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

@testset "eeg_matrix_to_dataframe" begin
    eeg_matrix_to_dataframe(rand(2, 2))
end

@testset "contours" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        visual = (; enlarge = 0.9, contours = (; linewidth = 1, color = :black)),
    )
end

@testset "contours.levels" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        visual = (;
            enlarge = 0.9,
            contours = (; linewidth = 1, color = :black, levels = 3),
        ),
    )
end

@testset "contours.levels" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        visual = (;
            enlarge = 0.9,
            contours = (; linewidth = 1, color = :black, levels = [0, 0.2]),
        ),
    )
end

@testset "adjustable colorbar" begin
    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df;
        bin_width = 80,
        positions = positions,
        colorbar = (; height = 100, width = 30),
        axis = (; aspect = AxisAspect(1)),
    )
    Box(f[1, 1], color = (:red, 0.2), strokewidth = 0)
    f
end

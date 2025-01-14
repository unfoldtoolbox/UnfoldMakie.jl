# simple checks

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
df_uncert = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 2], string.(1:length(positions)))
bin_width = 80

@testset "eeg_array_to_dataframe" begin
    eeg_array_to_dataframe(rand(2, 2))
end

@testset "eeg_topoplot_series" begin
    matrix = rand(64, 5) # simulated data
    UnfoldMakie.eeg_topoplot_series(
        matrix;
        layout = [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)],
        positions = positions,
    )
end

@testset "toposeries: bin_width" begin
    plot_topoplotseries(df; bin_width = 80, positions = positions)
end

@testset "toposeries: bin_num" begin
    plot_topoplotseries(df; bin_num = 5, positions = positions)
end

@testset "toposeries: bin_num" begin
    plot_topoplotseries(df; bin_num = 5, positions = positions, axis = (; xlabel = "test"))
end

@testset "toposeries: checking other y value" begin
    df.cont = df.time .* 3
    plot_topoplotseries(df; bin_num = 5, positions = positions, mapping = (; col = :cont))
end

#= @testset "toposeries: Δbin deprecated" begin #fail
    plot_topoplotseries(df, Δbin; positions = positions)
end =#

@testset "toposeries: nrows = 2" begin
    plot_topoplotseries(df; bin_num = 5, nrows = 2, positions = positions)
end

@testset "toposeries: nrows = 5" begin
    plot_topoplotseries(df; bin_num = 5, nrows = 3, positions = positions)
end

@testset "toposeries: nrows = -6" begin
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

@testset "toposeries: channel names true" begin
    plot_topoplotseries(
        df;
        bin_width = 80,
        nrows = 3,
        positions = positions,
        visual = (; label_text = true),
    )
end

@testset "toposeries: channel names given by user" begin
    df_30 = UnfoldMakie.eeg_array_to_dataframe(dat[1:30, :, 1], string.(1:30))

    plot_topoplotseries(
        df_30;
        bin_width = 80,
        nrows = 3,
        positions = positions[1:30],
        labels = raw_ch_names,
        visual = (; label_text = true),
    )
end

@testset "error checking: different length of channel names gand positions" begin
    err1 = nothing
    t() = error(
        plot_topoplotseries(
            df;
            bin_width = 80,
            nrows = 3,
            positions = positions,
            labels = raw_ch_names,
            visual = (; label_text = true),
        ),
    )
    try
        t()
    catch err1
    end
    @test err1 == ErrorException(
        "The length of `labels` differs from the length of `position`. Please make sure they are the same length.",
    )
end

@testset "toposeries: xlabel as text" begin
    f = Figure()
    ax = Axis(f[1, 1])
    plot_topoplotseries!(f[1, 1], df; bin_width = 80, positions = positions)
    text!(ax, 0, 0, text = "Time [ms] ", align = (:center, :center), offset = (0, -120))
    hidespines!(ax) # delete unnecessary spines (lines)
    hidedecorations!(ax, label = false)
    f
end

@testset "toposeries: one time point (what is it?)" begin
    plot_topoplotseries(
        df;
        bin_width = 80,
        positions = positions,
        combinefun = x -> x[end÷2],
    )
end

@testset "toposeries: differend comb functions" begin
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

@testset "toposeries: no colorbar" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        layout = (; use_colorbar = false),
    )
end

@testset "toposeries: GridPosition with a title" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)))

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

@testset "toposeries: specified xlabel" begin
    plot_topoplotseries(df; bin_width, positions = positions, axis = (; xlabel = "test"))
end

@testset "toposeries: adjustable colorrange" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        visual = (; colorrange = (-3, 3)),
    )
end

@testset "toposeries: visual.colorrange and colorbar.colorrange" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        colorbar = (; colorrange = (-1, 1)),
        visual = (; colorrange = (-1, 1)),
    )
end

@testset "toposeries: adjusted ylim_topo" begin
    plot_topoplotseries(
        df;
        bin_width,
        positions = positions,
        axis = (; ylim_topo = (0, 0.7)),
    )
end

@testset "toposeries: GridSubposition" begin
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

@testset "adjustable colorbar" begin #need to be elaborated
    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df;
        bin_width = 80,
        positions = positions,
        colorbar = (; height = 100, width = 30),
        axis = (; aspect = AxisAspect(1)),
    )
    #Box(f[1, 1], color = (:red, 0.2), strokewidth = 0)
    f
end

@testset "toposeries: precision" begin
    df.time = df.time .+ 0.5555
    plot_topoplotseries(df; bin_num = 5, positions = positions)
end

@testset "toposeries: colgap" begin
    with_theme(colgap = 50) do
        plot_topoplotseries(df, bin_num = 5; positions = positions)
    end
end

@testset "toposeries: colgap for subsets" begin
    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df,
        bin_num = 5;
        positions = positions,
        topoplot_axes = (; limits = (-0.05, 1.05, -0.1, 1.05)),
    )
    f
end

@testset "toposeries: change interpolation" begin
    plot_topoplotseries(
        df;
        bin_num = 2,
        positions = positions,
        topo_attributes = (; interpolation = DelaunayMesh()),
    )
end

@testset "toposeries: uncertainty - second row" begin
    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df;
        bin_num = 5,
        positions = positions,
        axis = (; xlabel = ""),
        colorbar = (; label = "Voltage estimate"),
    )
    plot_topoplotseries!(
        f[2, 1],
        df_uncert;
        bin_num = 5,
        positions = positions,
        visual = (; colormap = :viridis),
        axis = (; xlabel = "50 ms"),
        colorbar = (; label = "Voltage uncertainty"),
    )
    f
end

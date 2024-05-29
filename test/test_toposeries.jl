dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
Δbin = 80

@testset "toposeries basic with Δbin" begin
    plot_topoplotseries(df; Δbin, positions = positions)
end

@testset "toposeries basic with num_bin" begin
    plot_topoplotseries(df; num_bin = 5, positions = positions)
end

@testset "toposeries basic with channel names" begin
    plot_topoplotseries(df; Δbin, positions = positions, labels = raw_ch_names)
end

@testset "toposeries with xlabel" begin
    f = Figure()
    ax = Axis(f[1, 1])
    plot_topoplotseries!(f[1, 1], df; Δbin, positions = positions)
    text!(ax, 0, 0, text = "Time [ms] ", align = (:center, :center), offset = (0, -120))
    hidespines!(ax) # delete unnecessary spines (lines)
    hidedecorations!(ax, label = false)
    f
end

@testset "toposeries for one time point" begin
    plot_topoplotseries(df; Δbin, positions = positions, combinefun = x -> x[end÷2])
end

@testset "toposeries with differend comb functions " begin
    f = Figure(size = (500, 500))
    plot_topoplotseries!(
        f[1, 1],
        df;
        Δbin,
        positions = positions,
        combinefun = mean,
        axis = (; title = "combinefun = mean"),
    )
    plot_topoplotseries!(
        f[2, 1],
        df;
        Δbin,
        positions = positions,
        combinefun = median,
        axis = (; title = "combinefun = median"),
    )
    plot_topoplotseries!(
        f[3, 1],
        df;
        Δbin,
        positions = positions,
        combinefun = std,
        axis = (; title = "combinefun = std"),
    )
    f
end

@testset "toposeries without colorbar" begin
    plot_topoplotseries(df; Δbin, positions = positions, layout = (; use_colorbar = false))
end

@testset "GridPosition with a title" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")

    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))

    Δbin = 80
    a = plot_topoplotseries!(
        f[1:2, 1:5],
        df;
        Δbin,
        positions = positions,
        layout = (; use_colorbar = true),
    )
    hidespines!(ax)
    hidedecorations!(ax, label = false)

    f
end


@testset "14 topoplots and GridPosition" begin # horrific
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    Δbin = 30
    plot_topoplotseries!(
        f[1, 1:5],
        df;
        Δbin,
        positions = positions,
        visual = (label_scatter = false,),
    )
    f
end


@testset "row faceting, 2 conditions" begin
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    plot_topoplotseries!(
        f[1:2, 1:2],
        df;
        Δbin,
        col_labels = true,
        mapping = (; row = :condition),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
end

@testset "row faceting, 5 conditions" begin
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D", "E"], size(df, 1) ÷ 5)

    f = Figure(size = (600, 500))
    plot_topoplotseries!(
        f[1:2, 1:2],
        df;
        Δbin,
        col_labels = true,
        mapping = (; row = :condition),
        axis = (; ylabel = "Conditions"),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
end

@testset "facetting by layout" begin
    df = UnfoldMakie.eeg_matrix_to_dataframe(
        dat[:, 200:1:205, 1],
        string.(1:length(positions)),
    )

    f = Figure(size = (600, 500))
    plot_topoplotseries!(
        f[1:2, 1:2],
        df;
        Δbin = 1,
        col_labels = true,
        mapping = (; layout = :time),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
end

@testset "toposeries with xlabel" begin
    plot_topoplotseries(df; Δbin, positions = positions, axis = (; xlabel = "test"))
end

@testset "toposeries with adjustable colorrange" begin
    plot_topoplotseries(
        df;
        Δbin,
        positions = positions,
        colorbar = (; colorrange = (-1, 1)),
    )
end

@testset "toposeries with xlabel" begin
    plot_topoplotseries(df; Δbin, positions = positions, axis = (; ylim_topo = (0, 0.7)))
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
    UnfoldMakie.eeg_topoplot_series(df; Δbin = 5, positions = pos)
end =#

@testset "toposeries with GridSubposition" begin
    f = Figure(size = (500, 500))
    plot_topoplotseries!(
        f[2, 1][1, 1],
        df;
        Δbin,
        positions = positions,
        combinefun = mean,
        axis = (; title = "combinefun = mean"),
    )
end

@testset "interactive data" begin
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    df_obs = Observable(df)

    plot_topoplotseries!(
        f[1:2, 1:2],
        df_obs;
        Δbin,
        col_labels = true,
        mapping = (; row = :condition),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
    df = to_value(df_obs)
    df.estimate .= rand(length(df.estimate))
    df_obs[] = df
end

@testset "interactive scatter markers" begin
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    obs_tuple = Observable((0, 0, 0))
    plot_topoplotseries(
        df;
        Δbin = 0,
        col_labels = true,
        mapping = (; col = :condition),
        positions = positions,
        visual = (label_scatter = (markersize = 15, strokewidth = 2),),
        layout = (; use_colorbar = true),
        interactive_scatter = obs_tuple,
    )
end

@testset "categorical columns" begin
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    plot_topoplotseries!(
        f[1:2, 1:2],
        df;
        Δbin = 0,
        col_labels = true,
        mapping = (; col = :condition),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
end

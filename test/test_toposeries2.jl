# advanced features: facetting and interactivity

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
bin_width = 80

@testset "14 topoplots, 4 rows" begin # horrific
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    plot_topoplotseries!(
        f[1, 1:5],
        df;
        bin_num = 14,
        nrows = 4,
        positions = positions,
        visual = (; label_scatter = false),
    )
    f
end

@testset "facetting by layout" begin # could be changed to nrwos = "auto"
    df = UnfoldMakie.eeg_matrix_to_dataframe(
        dat[:, 200:1:206, 1],
        string.(1:length(positions)),
    )

    f = Figure(size = (600, 500))
    plot_topoplotseries!(
        f[1:2, 1:2],
        df;
        bin_width = 1,
        mapping = (; layout = :time),
        positions = positions,
    )
    f
end

@testset "categorical columns" begin
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    plot_topoplotseries!(
        f[1, 1],
        df;
        col_labels = true,
        mapping = (; col = :condition),
        positions = positions,
    )
    f
end

@testset "4 conditions" begin
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:4, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D"], size(df, 1) ÷ 4)

    f = Figure(size = (600, 500))
    plot_topoplotseries!(
        f[1, 1],
        df;
        positions = positions,
        col_labels = true,
        axis = (; ylabel = "Conditions"),
        mapping = (; col = :condition),
    )
    f
end

@testset "4 conditions in 2 rows" begin # TBD
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:4, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D"], size(df, 1) ÷ 4)

    f = Figure(size = (600, 500))
    plot_topoplotseries!(
        f[1, 1],
        df;
        nrows = 2,
        positions = positions,
        col_labels = true,
        axis = (; ylabel = "Conditions"),
        mapping = (; col = :condition),
    )
    f
end

@testset "change xlabel" begin
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    plot_topoplotseries!(
        f[1, 1],
        df;
        col_labels = true,
        mapping = (; col = :condition),
        axis = (; xlabel = "test"),
        positions = positions,
    )
    f
end

# use with WGlMakie
@testset "interactive data" begin
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    df_obs = Observable(df)

    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df_obs;
        col_labels = true,
        mapping = (; col = :condition),
        positions = positions,
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
        col_labels = true,
        mapping = (; col = :condition),
        positions = positions,
        visual = (; label_scatter = (markersize = 15, strokewidth = 2)),
        interactive_scatter = obs_tuple,
    )
end

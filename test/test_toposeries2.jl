# advanced features: facetting and interactivity

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
bin_width = 80

@testset "14 topoplots and GridPosition" begin # horrific
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    bin_width = 30
    plot_topoplotseries!(
        f[1, 1:5],
        df;
        bin_width,
        nrows = 14, 
        positions = positions,
        visual = (; label_scatter = false),
    )
    f
end

@testset "14 topoplots and GridPosition" begin # horrific
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    bin_width = 30
    plot_topoplotseries!(
        f[1, 1:5],
        df;
        bin_width,
        nrows = -1, 
        positions = positions,
        visual = (; label_scatter = false),
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
        bin_width,
        col_labels = true,
        mapping = (; row = :condition),
        positions = positions,
        visual = (; label_scatter = false),
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
        bin_width,
        col_labels = true,
        mapping = (; row = :condition),
        axis = (; ylabel = "Conditions"),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
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
        col_labels = false,
        mapping = (; layout = :time),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
end


@testset "interactive data" begin
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    df_obs = Observable(df)

    plot_topoplotseries!(
        f[1:2, 1:2],
        df_obs;
        bin_width,
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
        col_labels = true,
        mapping = (; col = :condition),
        positions = positions,
        visual = (label_scatter = false,),
        layout = (; use_colorbar = true),
    )
    f
end

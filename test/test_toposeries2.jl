# advanced features: facetting and interactivity

dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
bin_width = 80

@testset "14 topoplots, 4 rows" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    plot_topoplotseries(
        df;
        bin_num = 14,
        nrows = 4,
        positions = positions,
        visual = (; label_scatter = false),
    )
end

@testset "facetting by layout" begin # could be changed to nrwos = "auto"
    df = UnfoldMakie.eeg_array_to_dataframe(
        dat[:, 200:1:206, 1],
        string.(1:length(positions)),
    )

    plot_topoplotseries(
        df;
        bin_width = 1,
        mapping = (; layout = :time),
        positions = positions,
    )
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

@testset "error checking: bin_width or bin_num with categorical columns" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    err1 = nothing
    t() = error(
        plot_topoplotseries(
            df;
            bin_num = 5,
            mapping = (; col = :condition),
            positions = positions,
        ),
    )
    try
        t()
    catch err1
    end
    @test err1 == ErrorException(
        "Parameters `bin_width` or `bin_num` are only allowed with continonus `mapping.col` or `mapping.row`, while you specifed categorical.",
    )
end

@testset "categorical columns" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)
    select!(df, Not(:time, :group, :color, :label_aliases))

    plot_topoplotseries(df; mapping = (; col = :condition), positions = positions)
end

@testset "4 conditions" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:4, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D"], size(df, 1) ÷ 4)

    plot_topoplotseries(
        df;
        positions = positions,
        axis = (; xlabel = "Conditions"),
        mapping = (; col = :condition),
    )
end

@testset "4 conditions in 2 rows" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:4, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D"], size(df, 1) ÷ 4)

    plot_topoplotseries(
        df;
        nrows = 2,
        positions = positions,
        mapping = (; col = :condition),
    )
end
#=
@testset "4 condtions in rows" begin # TBD
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:4, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D"], size(df, 1) ÷ 4)

    plot_topoplotseries(
        df;
        bin_num = 3,
        positions = positions,
        mapping = (; row = :condition),
    )
end
=#

@testset "topoplot axes configuration" begin # TBD
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:4, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B", "C", "D"], size(df, 1) ÷ 4)

    plot_topoplotseries(
        df;
        nrows = 2,
        positions = positions,
        mapping = (; col = :condition),
        axis = (; title = "axis title", xlabel = "Conditions"),
        topoplot_axes = (;
            rightspinevisible = true,
            xlabelvisible = false,
            title = "single topoplot title",
        ),
    )
end

@testset "change xlabel" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    plot_topoplotseries(
        df;
        mapping = (; col = :condition),
        axis = (; xlabel = "test"),
        positions = positions,
    )
end

# use with WGlMakie
@testset "interactive data" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    df_obs = Observable(df)
    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df_obs;
        mapping = (; col = :condition),
        positions = positions,
    )
    f
    df = to_value(df_obs)
    df.estimate .= rand(length(df.estimate))
    df_obs[] = df
end

@testset "interactive scatter markers" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)

    obs_tuple = Observable((0, 0, 0))
    plot_topoplotseries(
        df;
        mapping = (; col = :condition),
        positions = positions,
        visual = (; label_scatter = (markersize = 15, strokewidth = 2)),
        interactive_scatter = obs_tuple,
    )
end

@testset "interactive data in eeg_array_to_dataframe" begin
    data_obs3 = Observable(UnfoldMakie.eeg_array_to_dataframe(rand(10, 20)))
    plot_topoplotseries!(Figure(), data_obs3; bin_num = 5, positions = rand(Point2f, 10))
    data_obs3[] = UnfoldMakie.eeg_array_to_dataframe(rand(10, 20))
end

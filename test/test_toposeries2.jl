using AlgebraOfGraphics: row_labels!
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
    @test_throws ErrorException begin
        plot_topoplotseries(df; bin_width = 80, bin_num = 5, positions = positions)
    end
end

@testset "error checking: bin_width or bin_num with categorical columns" begin
    @test_throws ErrorException begin
        df =
            UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
        df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)
        plot_topoplotseries(
            df;
            bin_num = 5,
            mapping = (; col = :condition),
            positions = positions,
        )
    end
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

begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:12, 1], string.(1:length(positions)))
    df.condition = repeat(repeat(["A", "B", "C"], inner = 4), 64)
    df.time = repeat(repeat([1, 2, 3, 4], outer = 3), 64)
    @testset "row-mapping by 3 conditions" begin
        plot_topoplotseries(
            df;
            bin_num = 4,
            positions = positions,
            mapping = (; row = :condition),
        )
    end
    @testset "row-mapping by 3 conditions + row_labels from user" begin
        plot_topoplotseries(
            df;
            bin_num = 4,
            positions = positions,
            row_labels = ["AA", "BB", "CC"],
            mapping = (; row = :condition),
        )
    end
    @testset "error: incorrect number of row labels" begin
        @test_throws ArgumentError begin
            plot_topoplotseries(
                df;
                bin_num = 4,
                positions = positions,
                row_labels = ["AA", "BB"],
                mapping = (; row = :condition),
            )
        end
    end
end

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


@testset "toposeries: differend combine functions for categorical" begin
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, 1:2, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)
    f = Figure(size = (500, 500))
    plot_topoplotseries!(
        f[1, 1],
        df;
        mapping = (; col = :condition),
        positions = positions,
        combinefun = mean,
        axis = (; xlabel = "", title = "combinefun = mean"),
    )
    plot_topoplotseries!(
        f[2, 1],
        df;
        mapping = (; col = :condition),
        positions = positions,
        combinefun = median,
        axis = (; xlabel = "", title = "combinefun = median"),
    )
    plot_topoplotseries!(
        f[3, 1],
        df;
        mapping = (; col = :condition),
        positions = positions,
        combinefun = std,
        axis = (; xlabel = "", title = "combinefun = std"),
    )

    f
end

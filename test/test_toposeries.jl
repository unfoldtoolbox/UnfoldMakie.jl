
@testset "standart" begin
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    Δbin = 80
    UnfoldMakie.plot_topoplotseries(df, Δbin; positions = positions)

end
@testset "standart without colorbar" begin
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    Δbin = 80
    UnfoldMakie.plot_topoplotseries(
        df,
        Δbin;
        positions = positions,
        layout = (; useColorbar = false),
    )

end

@testset "GridPosition with a title" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")


    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))

    Δbin = 80
    a = plot_topoplotseries!(
        f[1:2, 1:5],
        df,
        Δbin;
        positions = positions,
        layout = (; useColorbar = true),
    )
    hidespines!(ax)
    hidedecorations!(ax, label = false)

    f

end


@testset "14 topoplots and GridPosition" begin # horrific
    f = Figure()
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    Δbin = 30
    a = plot_topoplotseries!(
        f[5, 1:5],
        df,
        Δbin;
        positions = positions,
        visual = (label_scatter = false,),
    )
    f
end


@testset "multi-row" begin # just a trash
    f = Figure()

    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)
    Δbin = 30

    a = plot_topoplotseries!(
        f[5, 1:5],
        df,
        Δbin;
        mapping = (; row = :condition),
        positions = positions,
        visual = (label_scatter = false,),
    )

    f
end

data, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
Δbin = 80
raw_ch_names = [
    "FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7", "P9", "PO7", "PO3", "O1",
    "Oz", "Pz", "CPz", "FP2", "Fz", "F4", "F8", "FC4", "FCz", "Cz",
    "C4", "C6", "P4", "P8", "P10", "PO8", "PO4", "O2",
]

@testset "toposeries basic" begin
    plot_topoplotseries(df, Δbin; positions = positions)
end

@testset "toposeries basic with channel names" begin
    plot_topoplotseries(df, Δbin; positions = positions, labels = raw_ch_names)
end

@testset "toposeries with xlabel" begin
    f = Figure()
    ax = Axis(f[1, 1])
    plot_topoplotseries!(f[1, 1], df, Δbin; positions = positions)
    text!(ax, 0, 0, text = "Time [ms] ", align = (:center, :center), offset = (0, -120))
    hidespines!(ax) # delete unnecessary spines (lines)
    hidedecorations!(ax, label = false)
    f
end

@testset "toposeries for one time point" begin
    plot_topoplotseries(df, Δbin; positions = positions, combinefun = x -> x[end÷2])
end

@testset "toposeries with differend comb functions " begin
    f = Figure()
    plot_topoplotseries!(
        f[1, 1],
        df,
        Δbin;
        positions = positions,
        combinefun = mean,
        axis = (; title = "combinefun = mean"),
    )
    plot_topoplotseries!(f[2, 1], df, Δbin; positions = positions, combinefun = median)
    plot_topoplotseries!(f[3, 1], df, Δbin; positions = positions, combinefun = std)
    f
end

@testset "toposeries without colorbar" begin
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    Δbin = 80
    plot_topoplotseries(df, Δbin; positions = positions, layout = (; use_colorbar = false))
end

@testset "GridPosition with a title" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")

    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))

    Δbin = 80
    a = plot_topoplotseries!(
        f[1:2, 1:5],
        df,
        Δbin;
        positions = positions,
        layout = (; use_colorbar = true),
    )
    hidespines!(ax)
    hidedecorations!(ax, label = false)

    f

end


@testset "14 topoplots and GridPosition" begin # horrific
    f = Figure()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    Δbin = 30
    a = plot_topoplotseries!(
        f[1, 1:5],
        df,
        Δbin;
        positions = positions,
        visual = (label_scatter = false,),
    )
    f
end


@testset "multi-row" begin
    f = Figure()

    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))
    df.condition = repeat(["A", "B"], size(df, 1) ÷ 2)
    Δbin = 80

    a = plot_topoplotseries!(
        f[1:2, 1:2],
        df,
        Δbin;
        col_labels = true,
        mapping = (; row = :condition),
        positions = positions,
        visual = (label_scatter = false,),
    )
    f
end

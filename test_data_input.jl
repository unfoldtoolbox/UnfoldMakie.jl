include("../docs/example_data.jl")
df, pos = example_data("TopoPlots.jl")
dat, positions = TopoPlots.example_data()

@testset "ERP plot: Matrix data" begin
    plot_erp(dat[1, :, 1:2]')
end

@testset "ERP plot: Array data" begin
    plot_erp(dat[1, :, 1])
end

@testset "butterfly: Matrix as data input" begin
    tmp = DataFrame(channel = df.channel, estimate = df.estimate)
    grouped = groupby(tmp, :channel)
    mat = Matrix(reduce(hcat, [group.estimate for group in grouped])')
    plot_butterfly(mat; positions = pos)
end


@testset "topoplot: GridSubposition" begin
    f = Figure()
    data_for_topoplot =  UnfoldMakie.eeg_array_to_dataframe(rand(10)')
    plot_topoplot!(
        f[1, 1][1, 1],
        data_for_topoplot;
        positions = rand(Point2f, 10), labels = string.(1:10),
    )
    f
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

@testset "14 topoplots, 4 rows" begin # horrific
    df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)))
    plot_topoplotseries(
        df;
        bin_num = 14,
        nrows = 4,
        positions = positions,
        visual = (; label_scatter = false),
    )
end


@testset "eeg_array_to_dataframe" begin
    eeg_array_to_dataframe(rand(2, 2))
end
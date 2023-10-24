
@testset "testing standart" begin
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)));
    Δbin=80
    UnfoldMakie.plot_topoplotseries(df, Δbin; positions=positions)

end
@testset "testing with colorbar" begin
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)));
    Δbin=80
    UnfoldMakie.plot_topoplotseries(df, Δbin; positions=positions, layout = (; useColorbar=true))

end

@testset "testing with colorbar" begin
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)));
    Δbin=80
    UnfoldMakie.plot_topoplotseries(df, Δbin; positions=positions, layout = (; useColorbar=true))

end

@testset "testing with colorbar and Figure" begin
    f = Figure()
    ax = Axis(f[2, 1:5], aspect=DataAspect())

    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)))

    Δbin = 80
    chaLeng = 5
    x = Array(55:120:600)
    t = Array(-0.3:0.18:0.5)

    xlims!(low=0, high=600)
    ylims!(low=0, high=110)

    hidespines!(ax)
    hidedecorations!(ax, label=false)
    plot_topoplotseries!(f[1:2, 1:5], df, Δbin; positions=positions, visual=(label_scatter=false,), layout = (; useColorbar = true)) 


    f

end

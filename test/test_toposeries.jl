
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
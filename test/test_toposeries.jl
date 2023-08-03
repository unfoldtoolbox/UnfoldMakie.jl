# include("../UnfoldMakie/test/test_toposeries.jl")
#include("setup.jl")
@testset "testing calculateBBox" begin
    data, positions = TopoPlots.example_data()
    df = UnfoldMakie.eeg_matrix_to_dataframe(data[:, :, 1], string.(1:length(positions)));
    Δbin=80
    UnfoldMakie.plot_topoplotseries(df, Δbin; positions=positions)

end

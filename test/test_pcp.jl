
@testset "Figure, 3 channels, 1 condition" begin
    include("../docs/example_data.jl")
    results_plot, positions = example_data();
    plot_parallelcoordinates(results_plot; # this selects channel 5,3 & 2 
        mapping = (color = :coefname, y = :estimate))
end


@testset "GridPosition" begin
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched=true)

    f = Figure()
    plot_parallelcoordinates(f[1, 1], uf_5chan; 
        mapping=(; color=:coefname), layout=(; legend_position=:bottom));
    f
end
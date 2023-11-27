
@testset "Figure, 3 channels, 1 condition" begin
    include("../docs/example_data.jl")
    results_plot, positions = example_data()
    plot_parallelcoordinates(
        results_plot; # this selects channel 5,3 & 2 
        mapping = (color = :coefname, y = :estimate),
    )
end


@testset "GridPosition" begin
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")
    d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched = true)

    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        uf_5chan;
        mapping = (; color = :coefname),
        layout = (; legend_position = :bottom),
    )
    f
end

@testset "Bending" begin
    # check that the points actually go through the provided points
    f, b, c, d = UnfoldMakie.parallelplot(
        Figure(),
        [0 1 0 2 0 3 0 4.0; -1 0 -2 0 -3 0 -4 0]',
        normalize = :no,
        bend = true,
    )
    f

end

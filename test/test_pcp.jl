include("../docs/example_data.jl")
results_plot, positions = example_data()
@testset "PCP with Figure, 64 channels, 1 condition" begin
    plot_parallelcoordinates(results_plot; mapping = (color = :coefname, y = :estimate))
end


@testset "PCP with Figure, 5 channels (filtered), 1 condition" begin
    results_plot2 = filter(row -> row.channel <= 5, results_plot) # select channels
    plot_parallelcoordinates(results_plot2; mapping = (color = :coefname, y = :estimate))
end

@testset "PCP with Figure, 5 channels (subsetted), 1 condition" begin
    plot_parallelcoordinates(
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
    )
end


@testset "PCP with GridPosition" begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        results_plot;
        mapping = (color = :coefname, y = :estimate),
    )
    f
end

@testset "PCP with 3 conditions and 5 channels" begin
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")
    plot_parallelcoordinates(
        uf_5chan;
        mapping = (; color = :coefname),
        layout = (; legend_position = :right),
    )
end

@testset "Bending 1" begin
    # check that the points actually go through the provided points
    f, b, c, d = UnfoldMakie.parallelcoordinates(
        Figure(),
        [0 1 0 2 0 3 0 4.0; -1 0 -2 0 -3 0 -4 0]',
        normalize = :no,
        bend = true,
    )
    f
end

@testset "Bending 2" begin
    # check that the points actually go through the provided points
    f = Figure()
    plot_parallelcoordinates(f[1,1], 
        subset(results_plot, :channel=>x->x.<10), 
        bend=true
    )
    
    f
end


@testset "Normalisation of axis" begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
    )
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
        normalize = :minmax,
    )
    f
end

@testset "Axis labels" begin
    plot_parallelcoordinates(
        subset(results_plot, :channel => x -> x .< 5);
        visual = (; color = "#6BAED6"),
        ax_labels = ["Fz", "Cz", "O1", "O2"],
    )
end

@testset "Axis tick labels" begin
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :all,
        normalize = :minmax,
    ) # show all ticks on all axes
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :left,
        normalize = :minmax,
    ) # show all ticks on the left axis, but only extremities on others 
    plot_parallelcoordinates(
        f[3, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :outmost,
        normalize = :minmax,
    ) # show ticks on extremities of all axes

    plot_parallelcoordinates(
        f[4, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :none,
        normalize = :minmax,
    ) #  disable all ticks
    f 
end

@testset "transparency" begin
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")

    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        uf_5chan;
        mapping = (; color = :coefname),
        layout = (; legend_position = :right),
        visual=(; alpha=0.1)
    )
    plot_parallelcoordinates(
        f[2, 1],
        uf_5chan,
        mapping = (; color = :coefname),
        layout = (; legend_position = :right),
        visual=(; alpha=0.9)
    )
    f
end
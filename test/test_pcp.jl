include("../docs/example_data.jl")
results_plot, positions = example_data()
@testset "PCP with Figure, 64 channels, 1 condition" begin
    plot_parallelcoordinates(results_plot; 
    mapping = (color = :coefname, y = :estimate))
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


@testset "change colormap" begin
    # https://docs.makie.org/stable/explanations/colors/index.html
    # Use only categorical with high contrast between adjacent colors.
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
        visual = (; colormap = :tab10),
    )
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
        visual = (; colormap = :Accent_3),
    )
    for (label, layout) in zip(["tab10", "Accent_3"], [f[1, 1], f[2, 1]])
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, -50, 25, 0),
            halign = :left,
        )
    end
    f

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
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 10),
        bend = true,
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
    for (label, layout) in
        zip(["no normalisation", "minmax normalisation"], [f[1, 1], f[2, 1]])
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, -250, 25, 0),
            halign = :left,
        )
    end
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
    f = Figure(resolution = (400, 800))
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :all,
        normalize = :minmax,
    ) # show all ticks on all axes
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :left,
        normalize = :minmax,
    ) # show all ticks on the left axis, but only extremities on others 
    plot_parallelcoordinates(
        f[3, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :outmost,
        normalize = :minmax,
    ) # show ticks on extremities of all axes

    plot_parallelcoordinates(
        f[4, 1],
        subset(results_plot, :channel => x -> x .< 5, :time => x -> x .< 0);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :none,
        normalize = :minmax,
    ) #  disable all ticks
    for (label, layout) in
        zip(["all", "left", "outmost", "none"], [f[1, 1], f[2, 1], f[3, 1], f[4, 1]])
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, -80, 25, 0),
            halign = :left,
        )
    end
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
        visual = (; alpha = 0.1),
    )
    plot_parallelcoordinates(
        f[2, 1],
        uf_5chan,
        mapping = (; color = :coefname),
        layout = (; legend_position = :right),
        visual = (; alpha = 0.9),
    )
    for (label, layout) in zip(["alpha = 0.1", "alpha = 0.9"], [f[1, 1], f[2, 1]])
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, -80, 25, 0),
            halign = :left,
        )
    end
    f
end

@testset "styling" begin
    r1, positions = example_data()
    r2 = deepcopy(r1)
    r2.coefname .= "B" # create a second category
    r2.estimate .+= rand(length(r2.estimate)) * 0.1
    results_plot = vcat(r1, r2)

    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 8, :time => x -> x .< 0);
        mapping = (; color = :coefname),
        legend = (; framevisible = false),
        normalize = :minmax,
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7"],
    )
    f
end

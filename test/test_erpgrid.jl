data, pos = TopoPlots.example_data()
data = data[:, :, 1]

#times = -0.099609375:0.001953125:1.0

@testset "basic erpgrid: one plot is out of the border" begin
    plot_erpgrid(data[1:3, 1:20], pos)
end

@testset "basic erpgrid" begin
    plot_erpgrid(data[1:6, 1:20], pos)
end

@testset "erpgrid with GridPosition" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], data, pos)
    f
end


@testset "erpgrid change labels of legend" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], data, pos; axis = (; xlabel = "s", ylabel = "µV"))
    f
end

@testset "erpgrid plot in GridLayout" begin
    f = Figure(resolution = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    gb = f[2, 1] = GridLayout()
    gd = f[2, 2] = GridLayout()
    gc = f[3, 1] = GridLayout()
    ge = f[4, 1] = GridLayout()
    plot_erpgrid!(gb, data, pos; axis = (; xlabel = "s", ylabel = "µV"))
    for (label, layout) in zip(["A", "B", "C", "D", "E"], [ga, gb, gc, gd, ge])
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (0, 20, 22, -10),
            halign = :right,
        )
    end
    f
end

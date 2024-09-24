data, pos = TopoPlots.example_data()
data = data[:, :, 1]

df, pos2 = example_data("TopoPlots.jl")

@testset "erpgrid: one plot is out of the border" begin
    plot_erpgrid(data[1:3, :], pos[1:3])
end

@testset "erpgrid: data input with Matrix" begin
    plot_erpgrid(data[1:6, :], pos[1:6])
end

@testset "erpgrid: data input with DataFrame" begin
    df2 = unstack(df[:, [:estimate, :time, :channel]], :channel, :time, :estimate)
    select!(df2, Not(:channel))
    plot_erpgrid(df2, pos)
end

@testset "erpgrid: drawlabels" begin
    plot_erpgrid(data, pos; drawlabels = true)
end

@testset "erpgrid: drawlabels with user_defined channel names" begin
    plot_erpgrid(data[1:6, :], pos[1:6], raw_ch_names[1:6]; drawlabels = true)
end

@testset "erpgrid: customizable labels" begin
    plot_erpgrid(
        data[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        drawlabels = true,
        labels_grid_axis = (; color = :red),
    )
end

@testset "erpgrid: customizable vlines and hlines" begin
    plot_erpgrid(
        data[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        hlines_grid_axis = (; color = :red),
        vlines_grid_axis = (; color = :green),
    )
end

@testset "erpgrid: customizable lines" begin
    plot_erpgrid(
        data[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        lines_grid_axis = (; color = :red),
    )
end

@testset "erpgrid: GridPosition" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], data, pos)
    f
end

@testset "erpgrid: change x and y labels" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], data, pos; axis = (; xlabel = "s", ylabel = "µV"))
    f
end

@testset "erpgrid: GridLayout" begin
    f = Figure(size = (1200, 1400))
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


@testset "erpgrid: error of unequal data and positions" begin
    err1 = nothing
    t() = error(plot_erpgrid(data[1:6, :], pos[1:7], raw_ch_names[1:6]; drawlabels = true))
    try
        t()
    catch err1
    end
end

@testset "erpgrid: error of unequal ch_names and positions" begin
    err1 = nothing
    t() = error(plot_erpgrid(data[1:6, :], pos[1:6], raw_ch_names[1:7]; drawlabels = true))
    try
        t()
    catch err1
    end
end

dat, pos = TopoPlots.example_data()
dat = dat[:, :, 1]

df, pos2 = example_data("TopoPlots.jl")
channels_32, positions_32 = example_data("montage_32")

@testset "erpgrid: montage 32" begin
    plot_erpgrid(dat[1:32, :], positions_32, channels_32; drawlabels = true)
end

@testset "erpgrid: one plot is out of the border" begin
    plot_erpgrid(dat[1:3, :], pos[1:3])
end

@testset "erpgrid: data input with Matrix" begin
    plot_erpgrid(dat[1:6, :], pos[1:6])
end

@testset "erpgrid: data input with DataFrame" begin
    df2 = unstack(df[:, [:estimate, :time, :channel]], :channel, :time, :estimate)
    select!(df2, Not(:channel))
    plot_erpgrid(df2, pos)
end

@testset "erpgrid: drawlabels" begin
    plot_erpgrid(dat, pos; drawlabels = true)
end

@testset "erpgrid: drawlabels with user_defined channel names" begin
    plot_erpgrid(dat[1:6, :], pos[1:6], raw_ch_names[1:6]; drawlabels = true)
end

@testset "erpgrid: rounding coordinates" begin
    pos_new = [Point2(p[1], round(p[2] * 5) / 5) for p in pos]
    plot_erpgrid(dat, pos_new; drawlabels = true)
end

@testset "erpgrid: rounding coordinates 2" begin
    pos_new = [Point2(p[1], round(p[2], digits = 3)) for p in positions_32]
    plot_erpgrid(dat[1:32, :], pos_new, channels_32; drawlabels = true)
end

@testset "erpgrid: adding coordinates" begin
    pos_new = [Point2(p[1], round(p[2], digits = 3)) for p in positions_32]
    pos_new[31] = Point(pos_new[31][1] + 0.2, pos_new[31][2])

    plot_erpgrid(dat[1:32, :], pos_new, channels_32; drawlabels = true)
end

@testset "erpgrid: customizable labels" begin
    plot_erpgrid(
        dat[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        drawlabels = true,
        labels_grid_axis = (; color = :red),
    )
end

@testset "erpgrid: customizable vlines and hlines" begin
    plot_erpgrid(
        dat[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        hlines_grid_axis = (; color = :red),
        vlines_grid_axis = (; color = :green),
    )
end

@testset "erpgrid: customizable lines" begin
    plot_erpgrid(
        dat[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        lines_grid_axis = (; color = :red),
    )
end

@testset "erpgrid: customizable subaxes" begin
    plot_erpgrid(
        dat[1:6, :],
        pos[1:6],
        raw_ch_names[1:6];
        subaxes = (; width = Relative(0.2)),
    )
end

@testset "erpgrid: GridPosition" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], dat, pos)
    f
end

@testset "erpgrid: change x and y labels" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], dat, pos; axis = (; xlabel = "s", ylabel = "µV"))
    f
end

@testset "erpgrid: GridLayout" begin
    f = Figure(size = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    gb = f[2, 1] = GridLayout()
    gd = f[2, 2] = GridLayout()
    gc = f[3, 1] = GridLayout()
    ge = f[4, 1] = GridLayout()
    plot_erpgrid!(gb, dat, pos; axis = (; xlabel = "s", ylabel = "µV"))
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
    t() = error(plot_erpgrid(dat[1:6, :], pos[1:7], raw_ch_names[1:6]; drawlabels = true))
    try
        t()
    catch err1
    end
end

@testset "erpgrid: error of unequal ch_names and positions" begin
    err1 = nothing
    t() = error(plot_erpgrid(dat[1:6, :], pos[1:6], raw_ch_names[1:7]; drawlabels = true))
    try
        t()
    catch err1
    end
end

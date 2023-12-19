
include("../docs/example_data.jl")
data, pos = example_data("TopoPlots.jl")

@testset "butterfly basic" begin
    plot_butterfly(data; positions = pos)
end

@testset "butterfly basic with GridLayout" begin
    f = Figure()
    plot_butterfly!(f[1, 1], data; positions = pos)
end

@testset "butterfly with change of topomarkersize" begin
    plot_butterfly(
        data;
        positions = pos,
        topomarkersize = 10,
        topoheigth = 0.4,
        topowidth = 0.4,
    )
end

@testset "changing color from ROMA to gray" begin
    plot_butterfly(data; positions = pos, topopositions_to_color = x -> Colors.RGB(0.5))
end

@testset "changing color from ROMA to HSV" begin
    plot_butterfly(
        data;
        positions = pos,
        topopositions_to_color = UnfoldMakie.posToColorHSV,
    )
end

@testset "changing color from ROMA to RGB" begin
    plot_butterfly(
        data;
        positions = pos,
        topopositions_to_color = pos -> UnfoldMakie.posToColorRGB(pos),
    )
end


@testset "add h adn vlines in a Figure" begin
    f = Figure()
    plot_butterfly!(f, data; positions = pos)
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    f
end

@testset "add h- and vlines in GridPosition" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")
    plot_butterfly!(f[1:2, 1:5], data; positions = pos)
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    hidespines!(ax)
    hidedecorations!(ax, label = false)
    f
end

@testset "butterfly withiout decorations " begin
    plot_butterfly(
        data;
        positions = pos,
        layout = (;
            hidedecorations = (:label => true, :ticks => true, :ticklabels => true)
        ),
    )
end

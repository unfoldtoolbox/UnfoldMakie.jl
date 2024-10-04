
include("../docs/example_data.jl")
df, pos = example_data("TopoPlots.jl")

tmp = DataFrame(channel = df.channel, estimate = df.estimate)
grouped = groupby(tmp, :channel)
mat = Matrix(reduce(hcat, [group.estimate for group in grouped])')

@testset "butterfly: DataFrame as data input" begin
    plot_butterfly(df; positions = pos)
    #save("dev/UnfoldMakie/default_butterfly.png", f)
end

@testset "butterfly: Matrix as data input" begin
    plot_butterfly(mat; positions = pos)
end

@testset "butterfly: GridLayout for DataFrame" begin
    f = Figure()
    plot_butterfly!(f[1, 1], df; positions = pos)
end

@testset "butterfly: GridLayout for Matrix" begin
    f = Figure()
    plot_butterfly!(f[1, 1], mat; positions = pos)
end

@testset "butterfly: without topolegend" begin
    plot_butterfly(
        df;
        positions = pos,
        topopositions_to_color = x -> Colors.RGB(0.1),
        topolegend = false,
    )
    #save("dev/UnfoldMakie/basic_butterfly.png", f)
end

@testset "butterfly: change of topomarkersize" begin
    plot_butterfly(
        df;
        positions = pos,
        topomarkersize = 70,
        topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
    )
end

@testset "butterfly: change of interpolation" begin
    plot_butterfly(
        df;
        positions = pos,
        topo_interpolation = (; interpolation = DelaunayMesh()),
    )
end

@testset "butterfly: add h and vlines in a Figure" begin
    f = Figure()
    plot_butterfly!(f, df; positions = pos)
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    f
end

@testset "butterfly: add h- and vlines in GridPosition" begin
    f = Figure()
    ax = Axis(f[1:2, 1:5], aspect = DataAspect(), title = "Just a title")
    plot_butterfly!(f[1:2, 1:5], df; positions = pos)
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    hidespines!(ax)
    hidedecorations!(ax, label = false)
    f
end

@testset "butterfly: no decorations" begin
    f = Figure()
    plot_butterfly!(
        f[1, 1],
        df;
        positions = pos,
        topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
        layout = (;
            hidedecorations = (:label => true, :ticks => true, :ticklabels => true)
        ),
    )
    f
end

# Color schemes

@testset "changing color from ROMA to gray" begin
    plot_butterfly(df; positions = pos, topopositions_to_color = x -> Colors.RGB(0.5))
end

@testset "changing color from ROMA to HSV" begin
    plot_butterfly(
        df;
        positions = pos,
        topopositions_to_color = UnfoldMakie.pos_to_color_HSV,
    )
end

@testset "changing color from ROMA to RGB" begin
    plot_butterfly(
        df;
        positions = pos,
        topopositions_to_color = UnfoldMakie.pos_to_color_RGB,
    )
end

# would be nice these colors to be colowheeled
@testset "butterfly: changing color to veridis" begin
    plot_butterfly(
        df;
        positions = pos,
        visual = (; colormap = :viridis), # choose Makie colorscheme
    )
end

@testset "butterfly: changing color to romaO" begin
    plot_butterfly(df; positions = pos, visual = (; colormap = :romaO))
end
@testset "butterfly: changing color to gray" begin
    plot_butterfly(
        df;
        positions = pos,
        visual = (; colormap = [:gray]), # choose Makie colorscheme
    )
end
@testset "butterfly: changing color to HSV" begin
    plot_butterfly(
        df;
        positions = pos,
        visual = (; colormap = HSV.(range(0, 360, 10), 50, 50)), # choose Makie colorscheme
    )
end

# Channel highlighted
@testset "butterfly: with single color highlighted channel" begin
    f = pos -> UnfoldMakie.pos_to_color_RGB(pos)
    f =
        p ->
            p == pos[10] ? Colors.RGB(1, 0, 0) : Colors.RGB(128 / 255, 128 / 255, 128 / 255)
    plot_butterfly(df; positions = pos, topopositions_to_color = f)
end

# colors should be black and red
@testset "butterfly: with single color highlighted channel - 2" begin
    df.highlight = in.(df.channel, Ref(10))
    plot_butterfly(df; positions = pos, mapping = (; color = :highlight))
end

@testset "butterfly: with two color highlighted channel" begin
    df.highlight = in.(df.channel, Ref([10, 12]))
    plot_butterfly(df; positions = pos, mapping = (; color = :highlight))
end

@testset "butterfly: with two color highlighted channels and specified colormap" begin
    df.highlight = in.(df.channel, Ref([10, 12]))
    plot_butterfly(
        df;
        positions = pos,
        mapping = (; color = :highlight), # define channels to be highlighted by color 
        visual = (; colormap = :rust), # choose Makie colorscheme
    )
end

@testset "butterfly: with faceting of highlighted channels" begin
    df.highlight = in.(df.channel, Ref([10, 12]))
    df.highlight = replace(df.highlight, true => "channels 10, 12", false => "all channels")
    plot_butterfly(
        df;
        positions = pos,
        mapping = (; color = :highlight, col = :highlight),
        visual = (;
            color = 1:2,
            colormap = [Colors.RGB(128 / 255, 128 / 255, 128 / 255), :red],
        ),
    )
end

#TO DO
# not working
#= @testset "butterfly: with two size highlighted channels" begin
    df.highlight = in.(df.channel, Ref([10, 12]))
    plot_butterfly(df; positions = pos, mapping = (; linesize = :highlight))
end =#

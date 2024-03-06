include("../docs/example_data.jl")
uf = example_data("UnfoldLinearModel")
td = example_data("UnfoldTimeExpanded")

@testset "basic" begin
    plot_designmatrix(designmatrix(uf))
end

@testset "sort data" begin
    plot_designmatrix(designmatrix(uf); sort_data = true)
end

@testset "designmatrix plot in GridLayout" begin
    f = Figure(resolution = (1200, 1400))
    ga = f[1, 1] = GridLayout()
    plot_designmatrix!(ga, designmatrix(uf); sort_data = true)
    f
end

@testset "ticks specified" begin
    plot_designmatrix(designmatrix(uf); xticks = 10, sort_data = false)
end

@testset "hierarchical labels (bugged)" begin
    plot_designmatrix(designmatrix(td))
end
# axis labels should be also added

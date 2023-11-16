include("../docs/example_data.jl")
uf = example_data("UnfoldLinearModel")

@testset "basic" begin
    plot_designmatrix(designmatrix(uf))
end

@testset "sort data" begin
    plot_designmatrix(designmatrix(uf); sort_data = true)
end


@testset "designmatrix plot in GridLayout" begin
    f = Figure(resolution=(1200, 1400))
    ga = f[1, 1] = GridLayout()
    plot_designmatrix!(ga, designmatrix(uf); sort_data = true)
    f
end

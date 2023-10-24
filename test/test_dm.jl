@testset "basic" begin
    include("../docs/example_data.jl")
    uf = example_data("UnfoldLinearModel")
    plot_designmatrix(designmatrix(uf))
end

@testset "sort data" begin
    include("../docs/example_data.jl")
    uf = example_data("UnfoldLinearModel")
    plot_designmatrix(designmatrix(uf); sortData = true)
end

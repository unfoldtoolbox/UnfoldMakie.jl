data, pos = TopoPlots.example_data()
data = data[:, :, 1]

@testset "basic" begin
    f = Figure()
    plot_erpgrid!(f[1, 1], data, pos)
end


@testset "basic" begin
    plot_erpgrid(data, pos)
end

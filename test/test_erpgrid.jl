
@testset "basic" begin
    f = Figure()
    data, pos = TopoPlots.example_data()
    plot_erpgrid!(f[1, 1], data, pos)
end


@testset "basic" begin
    f = Figure()
    data, pos = TopoPlots.example_data()
    plot_erpgrid(f, data, pos)
    #save("erpimage.eps", f)
end
using BSplineKit, Unfold
m1 = example_data("UnfoldLinearModelwith1Spline")
m2 = example_data("UnfoldLinearModelwith2Splines")

@testset "Spline plot: basic" begin
    plot_splines(m1)
end

@testset "Spline plot: two spline terms" begin
    plot_splines(m2)
end

@testset "Spline plot: superlabel_axis check" begin
    plot_splines(m2; superlabel_kwargs = (; fontsize = 60))
end

@testset "Spline plot: spline_axis check" begin
    plot_splines(m2; spline_kwargs = (; ylabel = "test"))
end

@testset "Spline plot: density_axis check" begin
    plot_splines(m2, density_kwargs = (; ylabel = "test"))
end

using BSplineKit, Unfold
m1 = example_data("UnfoldLinearModelwith1Spline")
m2 = example_data("UnfoldLinearModelwith2Splines")

@testset "Spline plot: basic" begin
    plot_splines(m1)
end

@testset "Spline plot: two spline terms" begin
    plot_splines(m2)
end

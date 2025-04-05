import BSplineKit, Unfold
m0 = UnfoldMakie.example_data("UnfoldLinearModel")
m1 = UnfoldMakie.example_data("UnfoldLinearModelwith1Spline")
m2 = UnfoldMakie.example_data("UnfoldLinearModelwith2Splines")

@testset "Spline plot: no splines" begin
    err1 = nothing
    t() = error(plot_splines(m0))
    try
        t()
    catch err1
    end
    @test err1 == AssertionError(
        "No spline term is found in UnfoldModel. Does your UnfoldModel really have a `spl(...)` or other `AbstractSplineTerm`?",
    )
end

@testset "Spline plot: basic" begin
    plot_splines(m1)
end


@testset "Spline plot: GridLayout" begin
    f = Figure()
    plot_splines!(f, m1)
end

@testset "Spline plot: two spline terms" begin
    plot_splines(m2)
end

@testset "Spline plot: spline_axis check" begin
    plot_splines(m2; spline_axis = (; ylabel = "test"))
end

@testset "Spline plot: density_axis check" begin
    plot_splines(m2, density_axis = (; ylabel = "test"))
end

@testset "Spline plot: superlabel_axis check" begin
    plot_splines(m2; superlabel_config = (; fontsize = 60))
end

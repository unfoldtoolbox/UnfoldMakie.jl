import BSplineKit, Unfold
m0 = UnfoldMakie.example_data("UnfoldLinearModel")
m1 = UnfoldMakie.example_data("UnfoldLinearModelwith1Spline")
m2 = UnfoldMakie.example_data("UnfoldLinearModelwith2Splines")
m3 = UnfoldMakie.example_data("UnfoldLinearModelwith1SplineSecondPlace")

# to verife correctness of the superlabel
spline_superlabel(f) = only(filter(content -> content isa Label, f.content))
spline_superlabel_text(f) = spline_superlabel(f).text[]
const ONE_SPLINE_TITLE = "1 + condition + spl(continuous, 4)"
const TWO_SPLINES_TITLE =
    "1 + condition + spl(continuous, 4) + spl(continuous2, 6)"

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
    f = plot_splines(m1)
    @test spline_superlabel_text(f) == ONE_SPLINE_TITLE
end


@testset "Spline plot: GridLayout" begin
    f = Figure()
    plot_splines!(f, m1)
    @test spline_superlabel_text(f) == ONE_SPLINE_TITLE
end

@testset "Spline plot: two spline terms" begin
    f = plot_splines(m2)
    @test spline_superlabel_text(f) == TWO_SPLINES_TITLE
end

@testset "Spline plot: spline_axis check" begin
    f = plot_splines(m2; spline_axis = (; ylabel = "test"))
    @test spline_superlabel_text(f) == TWO_SPLINES_TITLE
end

@testset "Spline plot: density_axis check" begin
    f = plot_splines(m2, density_axis = (; ylabel = "test"))
    @test spline_superlabel_text(f) == TWO_SPLINES_TITLE
end

@testset "Spline plot: superlabel_axis check" begin
    f = plot_splines(m2; superlabel_config = (; fontsize = 60))
    @test spline_superlabel_text(f) == TWO_SPLINES_TITLE
    @test spline_superlabel(f).fontsize[] == 60
end

@testset "Spline plot: backgroundcolor" begin
    f = Figure(backgroundcolor = colorant"#F4F3EF")
    plot_splines!(
        f,
        m1;
        spline_axis = (; backgroundcolor = colorant"#F4F3EF"),
        density_axis = (; backgroundcolor = colorant"#F4F3EF"),
    )
    @test spline_superlabel_text(f) == ONE_SPLINE_TITLE
end

@testset "Spline plot: spline in second event formula" begin
    f = plot_splines(m3)
    @test spline_superlabel_text(f) == "1 + spl(continuous, 5)"
end

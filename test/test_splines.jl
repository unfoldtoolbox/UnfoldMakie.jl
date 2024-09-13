using BSplineKit, Unfold
m = example_data("UnfoldLinearModelwithSpline")

@testset "Spline plot:  basic" begin
    plot_splines(m)
end

#= rng = MersenneTwister(2) # make repeatable
n = 20 # datapoints
evts = DataFrame(:x => rand(rng, n))
signal = -(3 * (evts.x .- 0.5)) .^ 2 .+ 0.5 .* rand(rng, n)
signal = reshape(signal, length(signal), 1, 1)
signal = permutedims(signal, [3, 2, 1])
design_spl10 = [Any => (@formula(0 ~ 1 + spl(x, 10)), [0])];

uf_spl10 = fit(UnfoldModel, design_spl10, evts, signal);
term_spl = Unfold.formulas(uf_spl10)[1].rhs.terms[2]

basisSet = splFunction(0.0:0.01:1, term_spl)

basisSet = disallowmissing(basisSet[.!any(ismissing.(basisSet), dims = 2)[:, 1], :]) # remove missings
ax = Axis(Figure()[1, 1])
[lines!(ax, basisSet[:, k]) for k = 1:size(basisSet, 2)]
current_figure()
 =#

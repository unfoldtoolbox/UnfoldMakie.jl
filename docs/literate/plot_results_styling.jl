# # Styling of plot_results

using Unfold
using UnfoldMakie

using DataFrames
using CairoMakie


include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl")) # to load data
data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ = (-0.4, 0.8), sfreq = 50, name = "stimulus")
f = @formula 0 ~ 1 + conditionA + continuousA

bfDict = Dict(Any => (f, basisfunction))

m = fit(UnfoldModel, bfDict, evts, data);
results = coeftable(m);
nothing;

# # Styling your plot
# ## Mapping's
# Anything you can put in a `mapping(...)` can be modified as `AlgebraOfGraphics` object , for example:
plot_results(results, mapping = (; linestyle = :coefname))

# ## Adding P-values
# You must provide a dataframe with columns: `:from`,`:to`,future versions might allow a `:pvalue` column
pvals = DataFrame(
    :from => [0.1, 0.0, -0.1],
    :to => [0.5, 0.3, 0.6],
    :pvalue => [0.01, 0.01, 0.001], # optional
    :coefname => ["(Intercept)", "conditionA", "continuousA"],
)

plot_results(results, pvalue = pvals)

# !!! note
#   If you do not specify the `coefname`, all lines will have the same color as the first color grouping (typically coefname), and they may overlap!

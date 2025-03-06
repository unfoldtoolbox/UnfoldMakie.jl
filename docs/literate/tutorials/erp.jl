# # [ERP Plot](@id erp_vis)

# **ERP plot** is plot type for visualisation of [Event-related potentials](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3016705/). 
# It can fully represent time and experimental condition dimensions using lines.

# # Setup
# Package loading

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using DataFramesMeta
using UnfoldSim
using UnfoldMakie

# Data generation

# Let's generate some data. We'll fit a model with a 2 level categorical predictor and a continuous predictor with interaction.
data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
data = reshape(data, (1, size(data)...))
f = @formula 0 ~ 1 + condition + continuous
se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true);

m = fit(
    UnfoldModel,
    Dict(Any => (f, range(0, step = 1 / 100, length = size(data, 2)))),
    evts,
    data,
    solver = se_solver,
)
results = coeftable(m)
res_effects = effects(Dict(:continuous => -5:0.5:5), m);

# ## Figure plotting
# This is default figure:
plot_erp(results)

# To change legend title use `mapping.color`:
plot_erp(
    results,
    mapping = (; color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)

# # Additional features

# ## Effect plot

# Effect plot shows how ERP voltage is affected by variation of some variable (here: `:contionous`).

plot_erp(
    res_effects;
    mapping = (; y = :yhat, color = :continuous, group = :continuous),
    layout = (; use_colorbar = false),
    axis = (; xlabel = "Time [s]"),
)

# ## Significance lines

# - `significance::Array = []` - show a significance (see below). 

# Here we manually specify p-value lines. If array is not empty, plot shows colored lines under the plot representing the p-values. 
# Below is an example in which p-values are given:

m = example_data("UnfoldLinearModel")
results = coeftable(m)
significancevalues = DataFrame(
    from = [0.01, 0.2],
    to = [0.3, 0.4],
    coefname = ["(Intercept)", "condition: face"], # if coefname not specified, line should be black
)
plot_erp(
    results;
    :significance => significancevalues,
    mapping = (; color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)

# ## Error ribbons 

# - `stderror`::bool = `false` - add an error ribbon, with lower and upper limits based on the `:stderror` column.

# Display a colored band on the graph to indicate lower and higher estimates based on the standard error.
# For the generalizability of your results, it is always better to include error bands.

f = Figure()
results.coefname =
    replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
results = filter(row -> row.coefname != "continuous", results)
plot_erp!(
    f[1, 1],
    results;
    axis = (title = "Bad example", titlegap = 12, xlabel = ""),
    :stderror => false,
    mapping = (; color = :coefname => "Conditions"),
)

plot_erp!(
    f[2, 1],
    results;
    axis = (title = "Good example", titlegap = 12, xlabel = "Time [s]"),
    :stderror => true,
    mapping = (; color = :coefname => "Conditions"),
)

ax = Axis(f[2, 1], width = Relative(1), height = Relative(1))
xlims!(ax, [-0.04, 1])
ylims!(ax, [-0.04, 1])
hidespines!(ax)
hidedecorations!(ax)
text!(0.98, 0.2, text = "* Confidence\nintervals", align = (:right, :top))
f

# There are two ways to implement it.
# First is using `:stderror = true` after `;`.

results.se_low = results.estimate .- 0.5
results.se_high = results.estimate .+ 0.15
plot_erp(
    select(results, Not(:stderror));
    stderror = true,
    mapping = (; color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)

# Second way is to specify manually lower and higher borders of the error bands.

# !!! note
#        `:stderror` has precedence over `:se_low`/`:se_high`.

# ## Faceting
# Creation of column facets for each channel. 

m7 = example_data("7channels")
results7 = coeftable(m7)
plot_erp(
    results7,
    mapping = (; col = :channel, group = :channel, color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)

# # Configurations of ERP plot

# ```@docs
# plot_erp
# ```

# # [ERP plot](@id erp_vis)

# **ERP plot** is plot type for visualisation of [Event-related potentials](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3016705/) and also regression-ERPs. 
# It can fully represent such data features as time and experimental conditions using lines.
# Its key feature is the ability to display not only the ERPs themselves but also how they vary as a function of categorical or continuous predictors.
# # Setup
# **Package loading**

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using DataFramesMeta
using UnfoldSim

# **Data generation**

# Let's generate some data. We'll fit a model with a 2 level categorical predictor and a continuous predictor with interaction.
erp_matrix, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
erp_matrix = reshape(erp_matrix, (1, size(erp_matrix)...))
f = @formula 0 ~ 1 + condition + continuous
se_solver = (x, y) -> Unfold.solver_default(x, y, stderror = true);

m = fit(
    UnfoldModel,
    Dict(Any => (f, range(0, step = 1 / 100, length = size(erp_matrix, 2)))),
    evts,
    erp_matrix,
    solver = se_solver,
);
results = coeftable(m)
res_effects = effects(Dict(:continuous => -5:0.5:5), m); 

# ## Figure plotting
# This figure shows the rERP coeffiecients. The "Intercept" reflects the reference category, e.g. the ERP of a "car". The condition "face" reflects the difference to the intercept when a face is shown, and the continuous predictor reflects the slope associated with the linear effect of `continuous`.
plot_erp(results)

# To change legend title use `mapping.color`:
plot_erp(
    results,
    mapping = (; color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)

# # Additional features

# ## Effect plot

# Effect plot shows how the ERP is affected by variation of some variable (here: `:continuous`).

plot_erp(
    res_effects;
    mapping = (; y = :yhat, color = :continuous, group = :continuous),
    layout = (; use_colorbar = true),
    axis = (; xlabel = "Time [s]"),
)

# ## Significance Indicators
#
# Significance indicators visually highlight time intervals where model effects 
# (e.g., regression coefficients) are statistically significant.
#
# Indicators are specified via a `significance` DataFrame with at least:
# - `from` and `to`: the time interval to annotate (in seconds or samples)
# - optionally `coefname`: to label and color different effects
#
# The display is controlled using `sigifnicance_visual`, with options:
# - `:lines` — draw horizontal bars below the ERP curve
# - `:vspan` — draw vertical shaded spans over the time axis
# - `:both` — show both
# - `:none` — disable significance indicators entirely
#
# These visual indicators support interpretation of when and where effects occur.

# By default, significance is shown as vertical shaded spans.

m = UnfoldMakie.example_data("UnfoldLinearModel")
results = coeftable(m)
significancevalues = DataFrame(
    from = [0.01, 0.25],
    to = [0.2, 0.29],
    coefname = ["(Intercept)", "condition: face"], # if coefname not specified, line should be black
)
plot_erp(
    results;
    :significance => significancevalues,
    mapping = (; color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)
# This version shows both horizontal bands and vertical spans
#
# Additional styling is applied:
# - Vertical spans: lower alpha (transparency)
# - Horizontal bands: increased gap between stacked bands

plot_erp(
    results;
    significance = significancevalues,
    sigifnicance_visual = :both,
    significance_vspan = (; alpha = 0.2),
    significance_lines = (; gap = 0.05, alpha = 0.8),
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

m7 = UnfoldMakie.example_data("7channels")
results7 = coeftable(m7)
plot_erp(
    results7,
    mapping = (; row = :coefname, col = :channel, color = :channel),
    axis = (; xlabel = "Time [s]"),
    nticks = (3, 4),
)

# # Configurations of ERP plot

# ```@docs
# plot_erp
# ```

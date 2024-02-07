# ## [Line Plot Visualization](@id lp_vis)
# Here we discuss ERP plot visualization. 


# ## Package loading

# The following modules are necessary for following this tutorial:

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using DataFramesMeta
using UnfoldSim
using UnfoldMakie
include("../../../example_data.jl")

# ## Setup
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

# ## Plot the results
plot_erp(results; :stderror => true)



# ## Column Mappings for Line Plots
# `plot_erp` use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

# There are multiple default values, that are checked in that order if they exist in the `DataFrame`, a custom name can be chosen using
# `plot_erp(...; mapping=(; :y=:my_estimate)`

# :x Default is `(:x, :time)`.
# :y Default is `(:y, :estimate, :yhat)`.
# :color Default is `(:color, :coefname)`.

# # Configuration for Line Plots

# ## key values
# `plot_erp(...; <name>=<value>,...)`.
# - categorical_color (boolean, true) - in case of numeric `:color` column, treat `:color` as continuous or categorical variable.
# - categorical_group (boolean, true) - in case of numeric `:group` column, treat `:group` as categorical variable by default.
# - `topolegend` (bool, `false`): add an inlay topoplot with corresponding electrodes.
# - `stderror` (bool, `false`): add an error ribbon, with lower and upper limits based on the `:stderror` column.
# - `pvalue` (Array, `[]`): show a pvalue (see below). 

# Using some general configurations we can pretty up the default visualization. Here we use the following configuration:

plot_erp(
    res_effects;
    mapping = (; y = :yhat, color = :continuous, group = :continuous),
    legend = (; nbanks = 2),
    layout = (; show_legend = true, legend_position = :right),
    categorical_color = false,
    categorical_group = true,
)


# In the following we will use this "pretty" line plot as a basis for looking into configuration options.

# ## pvalue (array)
#
# Is an array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values. 
# Default is `[]` (an empty array).
# Below is an example in which `pvalue` are given:
m = example_data("UnfoldLinearModel")
results = coeftable(m)
pvals = DataFrame(
    from = [0.1, 0.3],
    to = [0.5, 0.7],
    coefname = ["(Intercept)", "condition: face"], # if coefname not specified, line should be black
)
plot_erp(results; :pvalue => pvals)

# ## stderror (boolean)
# Specifies whether to display a colored band on the graph to indicate lower and higher estimates based on the standard error.
# Default is `false`.
#
# Previously we showed `:stderror' - but low/high is also possible.
results.se_low = results.estimate .- 0.5
results.se_high = results.estimate .+ 0.15
plot_erp(select(results, Not(:stderror)); stderror = true)

# !!! note
#        as in the above code,`:stderror` has precedence over `:se_low`/`:se_high`


# # Configurations of ERP plot

# ```@docs
# plot_erp
# ```

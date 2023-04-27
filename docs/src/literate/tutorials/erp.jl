# ## [Line Plot Visualization](@id lp_vis)

# Here we discuss line plot visualization. 
# Make sure you have looked into the [installation instructions](@ref install_instruct).

# ## Include used Modules
# The following modules are necessary for following this tutorial:

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
using DataFramesMeta
using UnfoldSim
using UnfoldMakie

# # Setup things
# Let's generate some data and fit a model of a 2-level categorical and a continuous predictor with interaction.
data,evts = UnfoldSim.predef_eeg(;noiselevel=12,return_epoched=true)
data = reshape(data,(1,size(data)...))
f = @formula 0 ~ 1+condition+continuous 
se_solver =(x,y)->Unfold.solver_default(x,y,stderror=true)

m = fit(UnfoldModel, Dict(Any=>(f,range(0,step=1/100,length=size(data,2)))), evts, data,solver=se_solver)
results = coeftable(m)
res_effects = effects(Dict(:continuous=>-5:0.5:5),m)

# Plot the results
plot_erp(results; extra=(:stderror=>true,))



# ## Column Mappings for Line Plots
# `plot_erp` use a `DataFrame` as an input, the library needs to know the names of the columns used for plotting.

# There are multiple default values, that are checked in that order if they exist in the `DataFrame`, a custom name can be chosen using
# `plot_erp(...;mapping=(; :y=:myEstimate)`

# :x Default is `(:x, :time)`.
# :y Default is `(:y, :estimate, :yhat)`.
# :color Default is `(:color, :coefname)`.

# # Configuration for Line Plots

# ## extra
# `plot_erp(...;extra=(;<name>=<value>,...)`.
# - categoricalColor (boolean, true) - in case of numeric `:color` column, is color a continuous or categorical variable?
# - categoricalGroup (boolean, true) - in case of numeric `:group` column, treat `:group` as categorical variable by default
# - stderror (boolean, false) - add an error-ribbon based on the `:stderror` column
# - pvalue (see below)

# Using some general configurations we can pretty up the default visualization. Here we use the following configuration:

plot_erp(res_effects;
    mapping = (;y=:yhat,color=:continuous, group=:continuous),
    extra=(;showLegend=true,
                    categoricalColor=false,
                    categoricalGroup=true),
    legend  = (;nbanks=2),
    layout  = (;legendPosition=:right))




# In the following we will use this "pretty" line plot as a basis for looking into configuration options.

# ## pvalue (array)
#
# !!! important
#       this is currently broken!
#
# Is an array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values. 
# Default is `[]` (an empty array).

# Shown below is an example in which `pvalue` are given:
# pvals = DataFrame(
#		from=[0.1,0.3],
#		to=[0.5,0.7],
#		coefname=["(Intercept)","condition: face"] # if coefname not specified, line should be black
#	)
#
# plot_erp(results;extra= (;:pvalue=>pvals))

# ### stderror (boolean)
# Indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 
# Default is `false`.

# #previously we showed `:stderror`- but low/high is possible as well`
results.se_low = results.estimate .- 0.5
results.se_high = results.estimate .+ 0.15
plot_erp(select(results,Not(:stderror));extra= (;stderror=true))

# !!! note
#        as in the above code,`:stderror` has precedence over `:se_low`/`:se_high`




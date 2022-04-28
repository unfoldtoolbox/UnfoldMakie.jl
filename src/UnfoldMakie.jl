module UnfoldMakie

using Makie
using AlgebraOfGraphics
using Unfold
using DocStringExtensions # for Docu


include("plot_design.jl")
include("plot_results.jl")
include("plot_topoplot.jl")
export plot_results
export plot
export topoplot
export topoplot!
export Topoplot
export plot_topoplot
export plot_topoplot_series
# Write your package code here.

end

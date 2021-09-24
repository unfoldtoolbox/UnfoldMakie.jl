module UnfoldMakie

using Makie
using AlgebraOfGraphics
using Unfold


include("plot_design.jl")
include("plot_results.jl")
include("topoplot.jl")
export plot_results
export plot
export topoplot
# Write your package code here.

end

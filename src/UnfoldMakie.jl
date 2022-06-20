module UnfoldMakie

using Makie
using AlgebraOfGraphics
using Unfold

include("plot_config.jl")
using .PlotConfigs

include("plot_results.jl")
include("plot_design.jl")

export PlotConfig
export plot_lineTest
export plot_designTest
export plot_results
export plot
# Write your package code here.

end

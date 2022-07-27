module UnfoldMakie

using Makie
using AlgebraOfGraphics
using Unfold

include("plot_config.jl")
using .PlotConfigs

include("plot_results.jl")
include("plot_design.jl")
include("eegPositions.jl")
include("topoColor.jl")

export PlotConfig
# our plot functions
export plot_line
export plot_design

# legacy plot functions
export plot_results
export plot



end

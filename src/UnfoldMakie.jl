module UnfoldMakie

using Makie
using CairoMakie
using AlgebraOfGraphics
using Unfold
using Colors
using ColorSchemes

include("plot_config.jl")
using .PlotConfigs

include("plot_results.jl")
include("plot_design.jl")
include("plot_topo.jl")
include("plot_erp.jl")

include("eegPositions.jl")
include("topoColor.jl")

export PlotConfig
# our plot functions
export plot_line
export plot_design
export plot_erp
export plot_eeg_topo
export plot_topo

# legacy plot functions
export plot_results
export plot



end

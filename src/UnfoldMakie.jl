module UnfoldMakie

using Makie
using CairoMakie
using AlgebraOfGraphics
using Unfold
using Colors
using ColorSchemes

include("plotconfig.jl")

include("plot_line.jl")
include("plot_design.jl")
include("plot_topo.jl")
include("plot_erp.jl")
include("plot_paracoord.jl")

include("layout_helper.jl")
include("eeg_positions.jl")
include("topo_color.jl")

export PlotConfig
# our plot functions
export plot_line
export plot_line!
export plot_design
export plot_design!
export plot_erp
export plot_erp!
export plot_topo
export plot_topo!
export plot_paraCoord
export plot_paraCoord!

# legacy plot functions
export plot_results
export plot



end

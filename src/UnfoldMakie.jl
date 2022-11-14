module UnfoldMakie

using Makie
using CairoMakie
using AlgebraOfGraphics
using Unfold
using Colors
using ColorSchemes

include("example_data.jl")

include("plotconfig.jl")

include("plot_erp.jl")
include("plot_designmatrix.jl")
include("plot_topoplot.jl")
include("plot_erpimage.jl")
include("plot_parallelcoordinates.jl")

include("layout_helper.jl")
include("eeg_positions.jl")
include("topo_color.jl")

export PlotConfig


export plot_designmatrix
export plot_designmatrix!
export plot_erp
export plot_erp!
export plot_erpimage
export plot_erpimage!
export plot_topoplot
export plot_topoplot!
export plot_parallelcoordinates
export plot_parallelcoordinates!
export plot_butterfly
export plot_butterfly!

export nonnumeric
end
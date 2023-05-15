module UnfoldMakie

using Makie
#using CairoMakie
using AlgebraOfGraphics
using TopoPlots
using GridLayoutBase # for relative_axis

using Unfold
using ImageFiltering
using LinearAlgebra # for PCP
using Statistics

using Colors
using ColorSchemes
using ColorTypes

using DataStructures
using DataFrames
using SparseArrays
using CategoricalArrays # for cut for TopoPlotSeries

import Makie.hidedecorations!
import Makie.hidespines!
include("plotconfig.jl")

include("eeg-series.jl")
include("plot_topoplotseries.jl")

include("plot_erp.jl")
include("plot_designmatrix.jl")
include("plot_topoplot.jl")
include("plot_erpimage.jl")
include("plot_parallelcoordinates.jl")
include("plot_circulareegtopoplot.jl")

include("layout_helper.jl")
include("eeg_positions.jl")
include("topo_color.jl")
include("relative_axis.jl")

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
export plot_circulareegtopoplot
export plot_circulareegtopoplot!

export plot_topoplotseries
export plot_topoplotseries!

export nonnumeric
end

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

using DocStringExtensions # for $SIGNATURES

using Interpolations # for parallelplot

using DataStructures
using DataFrames
using SparseArrays
using CategoricalArrays # for cut for TopoPlotSeries
using StaticArrays

using CoordinateTransformations # for 3D positions to 2D

import Makie.hidedecorations!
import Makie.hidespines!
import AlgebraOfGraphics.hidedecorations!
#import AlgebraOfGraphics.hidespines!

include("plotconfig.jl")
include("docstringtemplate.jl")

include("eeg_series.jl")
include("plot_topoplotseries.jl")

include("plot_erp.jl")
include("plot_designmatrix.jl")
include("plot_topoplot.jl")
include("plot_erpimage.jl")
include("plot_parallelcoordinates.jl")
include("plot_circulareegtopoplot.jl")
include("plot_erpgrid.jl")

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
export plot_erpgrid
export plot_erpgrid!

export to_positions
export nonnumeric # reexport from AoG
end

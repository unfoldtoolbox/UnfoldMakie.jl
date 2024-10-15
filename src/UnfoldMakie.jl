module UnfoldMakie

import Makie.get_ticks
using Makie
#using CairoMakie
using AlgebraOfGraphics
using TopoPlots
using GridLayoutBase # for relative_axis

#using Unfold
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
include("docstring_template.jl")
include("supportive_defaults.jl")

include("eeg_series.jl")
include("plot_topoplotseries.jl")

include("plot_erp.jl")
include("plot_butterfly.jl")

#include("../ext/UnfoldMakieUnfoldExt/UnfoldMakieUnfoldExt.jl")
"""
    plot_splines()
    plot_splines!()
Please in addition load Unfold via  `using Unfold` to use this plot-type
"""
plot_splines() = error("This function is available after `using Unfold` and calling `plot_splines` with their respective arguments.")
plot_splines!() = plot_splines()

"""
    plot_designmatrix()
    plot_designmatrix!()
Please in addition load Unfold via  `using Unfold` to use this plot-type
"""
plot_designmatrix() = error("This function is available after `using Unfold` and calling `plot_designmatrix` with their respective arguments.")
plot_designmatrix!() = plot_designmatrix()

include("plot_topoplot.jl")
include("plot_erpimage.jl")
include("plot_parallelcoordinates.jl")
include("plot_circular_topoplots.jl")
include("plot_erpgrid.jl")
include("plot_channelimage.jl")

include("layout_helper.jl")
include("eeg_positions.jl")
include("topo_color.jl")
include("relative_axis.jl")

export PlotConfig

export plot_designmatrix
export plot_designmatrix!
export plot_splines
export plot_splines!
export plot_erp
export plot_erp!
export plot_erpimage
export plot_erpimage!
export plot_topoplot
export plot_topoplot!
export plot_parallelcoordinates

export plot_butterfly
export plot_butterfly!
export plot_circular_topoplots
export plot_circular_topoplots!

export plot_topoplotseries
export plot_topoplotseries!
export plot_erpgrid
export plot_erpgrid!
export plot_channelimage
export plot_channelimage!

export to_positions
export eeg_array_to_dataframe
export eeg_topoplot_series
export nonnumeric # reexport from AoG

end

module UnfoldMakie

import Makie.get_ticks
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

# Unfold Backward Compatability. AbstractDesignMatrix was introduced only in v0.7
if isdefined(Unfold, :AbstractDesignMatrix)
    # nothing to do for AbstractDesignMatrix, already imprted
    # backward compatible accessor
    const drop_missing_epochs = Unfold.drop_missing_epochs
    const modelmatrices = Unfold.modelmatrices
else
    const AbstractDesignMatrix = Unfold.DesignMatrix
    const drop_missing_epochs = Unfold.dropMissingEpochs
    const modelmatrices = Unfold.get_Xs
end

include("configs/configs.jl")
include("configs/configs_supportive.jl")
include("configs/topo_color.jl")

include("configs/docstring_template.jl")
include("configs/layout_helper.jl")
include("configs/relative_axis.jl")

include("data/eeg_positions.jl")

include("unfold_plots/plot_splines.jl")
include("unfold_plots/plot_designmatrix.jl")

include("general_plots/eeg_series.jl")
include("general_plots/plot_topoplotseries.jl")
include("general_plots/plot_topoplotseries_support.jl")
include("general_plots/plot_erp.jl")
include("general_plots/plot_butterfly.jl")
include("general_plots/plot_topoplot.jl")
include("general_plots/plot_erpimage.jl")
include("general_plots/plot_parallel_coordinates.jl")
include("general_plots/parallel_coordinates.jl")
include("general_plots/plot_circular_topoplots.jl")
include("general_plots/plot_erpgrid.jl")
include("general_plots/plot_channelimage.jl")



# extension functions
example_data(args...; kwargs...) =
    error("This function is only available after importing UnfoldSim")
example_montage(args...; kwargs...) =
    error("This function is only available after importing UnfoldSim")

export example_data
export example_montage

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



if !isdefined(Base, :get_extension)
    ## Extension Compatabality with julia pre 1.9
    include("../ext/UnfoldMakieUnfoldSimExt/UnfoldMakieUnfoldSimExt.jl")
end
end

# UnfoldMakie Documentation


This is the documentation of the UnfoldMakie module for the Julia programming language. 

## About

UnfoldMakie aims to allow users to create different types of visualizations. 
These include line plots, butterfly plots, design matrices, parallel coordinate plots, ERP images, and topo plots.
Building on the [Unfold](https://github.com/unfoldtoolbox/unfold.jl/) and [Makie](https://makie.juliaplots.org/stable/) Modules, it also allows users to customize the plots through an input configuration.

As can be seen from the types of visualizations possible, these configuration options try to enable the user to create plots that are helpful in the field of computational EEG.
One such example is the ability to use a topo plot as a legend for a line plot by allowing multiple visualizations within a figure.

![Coordinated Multiple Views](./images/every_plot.png)

## Structure

For ease of reading, the documentation is divided into sections that users can view based on their questions.

The `Tutorials: Setup` section contains all the information needed to get started, including [installation](@ref install_instruct).

The `Tutorials: Visualizations` section summarizes all possible visualizations and how users can create them. 
It also describes their unique configuration options. 

These visualizations are:
- [Designmatrices](@ref dm_vis)
- [Line Plots](@ref lp_vis)
- [Butterfly Plots](@ref bfp_vis)
- [ERP Images](@ref erpi_vis)
- [Topo Plots](@ref tp_vis)
- [Parallel Coordinate Plots](@ref pcp_vis)

The `Plot Configuration` shows all segments of the config, detailing the attributes they contain.
The plot config is the main interface that allows the user to access the various visualization options. Since the options can be quite different in nature, the plot config is further divided into categories.

These segments are:
- [Axis Data](@ref config_axis)
- [Colorbar Data](@ref config_colorbar)
- [Extra Data](@ref config_extra)
- [Layout Data](@ref config_layout)
- [Legend Data](@ref config_legend)
- [Mapping Data](@ref config_mapping)
- [Visual Data](@ref config_visual)

The `How To` section features information on how to achieve specific goals or deal with specific problems.

These segments are:
- [Fix Parallel Coordinates Plot](@ref ht_fpcp)
- [Show Out-of-bounds Labels for Designmatrix](@ref show_oob_labels)
- [Hide Axis Spines and Decorations](@ref ht_hide_deco)
- [Include multiple Visualizations in one Figure](@ref ht_mvf)
- [Show out of Bounds Label](@ref ht_soobl)

## Used Packages
Everything was tested with Julia v1.7.

The following module in their respective versions are used internally by UnfoldMakie:
- AlgebraOfGraphics v0.6.9
- CairoMakie v0.8.9
- Colors v0.12.8
- ColorSchemes v3.19.0
- DataFrames v1.3.4
- GeometryBasics v0.4.2
- ImageFiltering v0.7.1
- Makie v0.17.9
- Pipe v1.3.0
- PyMNE v0.1.2
- TopoPlots v0.1.0
- Unfold v0.3.11
- LinearAlgebra 
- SparseArrays
- Statistics

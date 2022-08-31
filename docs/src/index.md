# UnfoldMakie Documentation

This is the documentation of the UnfoldMakie module for the Julia programming language. 

## About

UnfoldMakie aims to allow users to generate different types of visualizations. 
These include line plots, butterfly plots, designmatrices, parallel coordinates plots, ERP images and topo plots.
Building on the `Unfold` and `Makie` Modules, it also grants users customizability through an input configuration on the plots.

As is apparent considering the types of possible visualizations, these config options try to enable users to create plots, that are helpful in the subject area of computational EEG.
One such example is the possibility of using a topo plot as a legend for a line plot.

## Structure

For easy readability, the documentation is divided into sections users can inspect depending on their query.

The `Tutorials: Setup` section contains all information to get started including [installation](@ref install_instruct) and how to aquire necessary [data](@ref test_data) for testing if the user has none.

The `Tutorials: Visualizations` section summarizes all possible visualizations and how users can generate them. 
It also details their unique configuration options.

These visualizations are:
- [Designmatrices](@ref dm_vis)
- [Line Plots](@ref lp_vis)
- [Butterfly Plots](@ref bfp_vis)
- [ERP Images](@ref erpi_vis)
- [Topo Plots](@ref tp_vis)
- [Parallel Coordinate Plots](@ref pcp_vis)

The `Plot Configuration` all segments of the config, detailing their contained attributes.
The plot config is the prime interface allowing the user to access the different visualition options. As the options can be quite different in nature, the plot config is further split into categories.
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
- [Generate a Timeexpanded Designmatrix](@ref ht_gen_te_designmatrix)
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

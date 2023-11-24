using Pkg
#Pkg.activate("/store/users/mikheev/projects/unfold_dev/")
#Pkg.activate("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie")
Pkg.status()

Pkg.instantiate()
Pkg.resolve()


pwd()
#include("dev/UnfoldMakie/test/test_toposeries.jl")
#include("test/test_toposeries.jl")


Pkg.activate("/store/users/mikheev/projects/unfold_dev/")
#Pkg.activate("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/")

include("test/setup.jl")
using UnfoldMakie

include("test/test_toposeries.jl")
#include("test/test_plot_circulareegtopoplot.jl")

include("test/runtests.jl")

include("test/test_erpimage.jl")
include("test/test_topoplot.jl")
include("test/test_all.jl")

# docs]

#Pkg.activate("/store/users/mikheev/projects/unfold_dev/UnfoldMakie/docs/")
#include("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/make.jl") 

using JuliaFormatter
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/eeg_series.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_circulareegtopoplot.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_designmatrix.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_erp.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_erpimage.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_parallelcoordinates.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_topoplot.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_topoplotseries.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_erpgrid.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plot_channelimage.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/plotconfig.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/src/UnfoldMakie.jl")


format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/src/tutorials/butterfly.md")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/src/literate/tutorials/circTopo.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/src/literate/tutorials/erp.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/example_data.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/make.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/docs/run_liveserver.jl")

format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/test_dm.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/test_erp.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/test_erpimage.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/test_erpgrid.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/test_butterfly.jl")
format_file("/store/users/mikheev/projects/unfold_dev/dev/UnfoldMakie/test/test_toposeries.jl")

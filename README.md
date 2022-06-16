# UnfoldMakie
Currently supports plotting designmatrices `plot(designmatrix(uf))` and results `plot_results(coeftable(uf))`. Check out the `topoplot` branch for topographical plotting.

The toolbox requires a Makie-Backend to be loaded, e.g. `using CairoMakie`

Parts of the toolbox can easily be used to plot any arbitrary EEG/Timeseries data; required tidy data-frame, with typical fields `:estimate` and `:time`

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev)
[![Build Status](https://github.com/unfoldtoolbox/UnfoldMakie.jl/workflows/CI/badge.svg)](https://github.com/unfoldtoolbox/UnfoldMakie.jl/actions)
[![Coverage](https://codecov.io/gh/behinger/UnfoldMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/behinger/UnfoldMakie.jl)


Plotting library for [Unfold](https://github.com/unfoldtoolbox/unfold.jl/)


### Citation
If you make use of theses visualizations, please cite [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6531996.svg)](https://doi.org/10.5281/zenodo.6531996)

### Funding
Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – project ID 251654672 – TRR 161 (project D05)

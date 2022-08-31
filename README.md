# UnfoldMakie


This is the UnfoldMakie module for the Julia programming language.

UnfoldMakie aims to allow users to generate different types of visualizations. 
Building on the [Unfold](https://github.com/unfoldtoolbox/unfold.jl/) and [Makie](https://makie.juliaplots.org/stable/) Modules, it also grants users customizability through an input configuration on the plots.


The toolbox requires a Makie-Backend to be loaded, e.g. `using CairoMakie`

As is apparent considering the types of possible visualizations, these config options try to enable users to plot any arbitrary EEG/Timeseries data; required tidy data-frame, with typical fields `:estimate` and `:time`

One such example is the possibility of using a topo plot as a legend for a line plot by allowing for multiple visualizations within one figure.

The supportet visualizations are:

- Designmatrix Plots
- Line Plots
- Butterfly Plots
- ERP Images
- Topo Plots
- Parallel Coordinates Plot

![Coordinated Multiple Views](docs/src/images/every_plot.png)

## Code Notes

The code files can be found in the `src` folder.

## Documentation Notes

The documentation can be found in the `doc` folder.
In the `src` folder contained within it exists as "raw" `.md` files and in the `build` folder contained within it exists as `.html`.
These are specifically the "index" file with more files in sub folders.


[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev)
[![Build Status](https://github.com/unfoldtoolbox/UnfoldMakie.jl/workflows/CI/badge.svg)](https://github.com/unfoldtoolbox/UnfoldMakie.jl/actions)
[![Coverage](https://codecov.io/gh/behinger/UnfoldMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/behinger/UnfoldMakie.jl)


## Citation
If you make use of theses visualizations, please cite [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6531996.svg)](https://doi.org/10.5281/zenodo.6531996)

## Authors

It was authored by `Benedikt Ehinger` and has been worked upon by students within the context of a university project (`Fachpraktikum:  Methods in Computational EEG`) at the University of Stuttgart.

The student names are:
- Baumgartner, Daniel
- Döring, Sören
- Gärtner, Niklas

## Funding
Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – project ID 251654672 – TRR 161 (project D05)

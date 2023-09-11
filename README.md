# UnfoldMakie

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev)
[![Build Status](https://github.com/unfoldtoolbox/UnfoldMakie.jl/workflows/CI/badge.svg)](https://github.com/unfoldtoolbox/UnfoldMakie.jl/actions)
[![Coverage](https://codecov.io/gh/behinger/UnfoldMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/behinger/UnfoldMakie.jl)


UnfoldMakie allows many visualizations for ERP and "Unfolded"-models.
Building on the [Unfold](https://github.com/unfoldtoolbox/unfold.jl/) and [Makie](https://makie.juliaplots.org/stable/), it grants users highly customizable plots.

The toolbox requires a Makie-Backend to be loaded, e.g. `using CairoMakie`

Some plotting functions require data-frames, with fields like `:estimate` or `:time`.

The supportet visualizations are:

- Designmatrices
- Line Plots
- Butterfly Plots
- ERP Images with option for sorting
- Topo Plots
- Topoplot series
- Parallel Coordinates Plot

![grafik](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/af2801e5-cd64-4932-b84d-9abc1d8470ee)


## Code Notes

The code files can be found in the `src` folder.

## Documentation Notes

The documentation can be found in the `doc` folder. We use `Documenter.jl` and plan to use `Literate.jl` for future usage.
In the `src` folder contained within it exists as "raw" `.md` files and in the `build` folder contained within it exists as `.html` after running the `make.jl` file.
These are specifically the "index" file with more files in sub folders.

## Citation
If you make use of theses visualizations, please cite [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6531996.svg)](https://doi.org/10.5281/zenodo.6531996)

## Authors

It was authored by `Benedikt Ehinger` and has been worked upon by students and doctoral researchers within the context of a university project (`Fachpraktikum:  Methods in Computational EEG`) at the University of Stuttgart.

The student names are:
- Baumgartner, Daniel
- Döring, Sören
- Gärtner, Niklas

Doctoral reserchers:
- Vladimir Mikheev

## Funding
Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – project ID 251654672 – TRR 161 (project D05)

# ![UnfoldMakie](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/57703446/26b770b3-afa0-4652-b654-82d2f737f42f)


[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev)
[![Build Status](https://github.com/unfoldtoolbox/UnfoldMakie.jl/workflows/CI/badge.svg)](https://github.com/unfoldtoolbox/UnfoldMakie.jl/actions)
[![Coverage](https://codecov.io/gh/behinger/UnfoldMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/behinger/UnfoldMakie.jl)

|rERP|EEG visualisation|EEG Simulations|BIDS pipeline|Decode EEG data|Statistical testing|
|---|---|---|---|---|---|
| <a href="https://github.com/unfoldtoolbox/Unfold.jl/tree/main"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623787-757575d0-aeb9-4d94-a5f8-832f13dcd2dd.png"></a> | <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl"><img  src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623793-37af35a0-c99c-4374-827b-40fc37de7c2b.png"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldSim.jl"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623795-328a4ccd-8860-4b13-9fb6-64d3df9e2091.png"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldBIDS.jl"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277622460-2956ca20-9c48-4066-9e50-c5d25c50f0d1.png"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldDecode.jl"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277622487-802002c0-a1f2-4236-9123-562684d39dcf.png"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldStats.jl"><img  src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623799-4c8f2b5a-ea84-4ee3-82f9-01ef05b4f4c6.png"></a>|

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

<details>
<summary>Click to see example plots</summary>
  
![grafik](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/af2801e5-cd64-4932-b84d-9abc1d8470ee)

</details>

## Install

### Installing Julia

<details>
<summary>Click to expand</summary>

The recommended way to install julia is [juliaup](https://github.com/JuliaLang/juliaup).
It allows you to, e.g., easily update Julia at a later point, but also test out alpha/beta versions etc.

TL:DR; If you dont want to read the explicit instructions, just copy the following command

#### Windows

AppStore -> JuliaUp,  or `winget install julia -s msstore` in CMD

#### Mac & Linux

`curl -fsSL https://install.julialang.org | sh` in any shell
</details>

### Installing Unfold

```julia
using Pkg
Pkg.add("UnfoldMakie")
```

## Quickstart

```julia
using UnfoldMakie
using CairoMakie

# TBA
```

## Contributions

Contributions are very welcome. These could be typos, bugreports, feature-requests, speed-optimization, new solvers, better code, better documentation.

### How-to Contribute

You are very welcome to raise issues and start pull requests!

### Adding Documentation

1. We recommend to write a Literate.jl document and place it in `docs/literate/FOLDER/FILENAME.jl` with `FOLDER` being `HowTo`, `Explanation`, `Tutorial` or `Reference` ([recommended reading on the 4 categories](https://documentation.divio.com/)).
2. Literate.jl converts the `.jl` file to a `.md` automatically and places it in `docs/src/generated/FOLDER/FILENAME.md`.
3. Edit [make.jl](https://github.com/unfoldtoolbox/Unfold.jl/blob/main/docs/make.jl) with a reference to `docs/src/generated/FOLDER/FILENAME.md`.

## Citation

If you make use of theses visualizations, please cite:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6531996.svg)](https://doi.org/10.5281/zenodo.6531996)

## Contributors (alphabetically)

- **Daniel Baumgartner**
- **Benedikt Ehinger**
- **Sören Döring**
- **Niklas Gärtner**
- **Vladimir Mikheev**

## Acknowledgements

Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – project ID 251654672 – TRR 161 (project D05)

Funded by Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) under Germany´s Excellence Strategy – EXC 2075 – 390740016

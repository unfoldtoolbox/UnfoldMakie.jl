# ![UnfoldMakie - Advanced EEG and ERP Plotting](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/57703446/26b770b3-afa0-4652-b654-82d2f737f42f)


[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev)
[![Build Status](https://github.com/unfoldtoolbox/UnfoldMakie.jl/workflows/CI/badge.svg)](https://github.com/unfoldtoolbox/UnfoldMakie.jl/actions)
[![Coverage](https://codecov.io/gh/behinger/UnfoldMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/behinger/UnfoldMakie.jl)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14500860.svg)](https://doi.org/10.5281/zenodo.14192333)
[![DOI](https://joss.theoj.org/papers/10.21105/joss.07560/status.svg)](https://doi.org/10.21105/joss.07560)
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-8-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->
[![Downloads](https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Fmonthly_downloads%2FUnfoldMakie&query=total_requests&suffix=%2Fmonth&label=Downloads)](https://juliapkgstats.com/pkg/UnfoldMakie)
[![Downloads](https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FUnfoldMakie&query=total_requests&suffix=%2Ftotal&label=Downloads)](https://juliapkgstats.com/pkg/UnfoldMakie)


|Estimation|Visualisation|Simulation|BIDS pipeline|Decoding|Statistics|MixedModelling|
|---|---|---|---|---|---|---|
| <a href="https://github.com/unfoldtoolbox/Unfold.jl/tree/main"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623787-757575d0-aeb9-4d94-a5f8-832f13dcd2dd.png" alt="Unfold.jl Logo"></a> | <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl"><img  src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623793-37af35a0-c99c-4374-827b-40fc37de7c2b.png" alt="UnfoldMakie.jl Logo"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldSim.jl"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623795-328a4ccd-8860-4b13-9fb6-64d3df9e2091.png" alt="UnfoldSim.jl Logo"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldBIDS.jl"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277622460-2956ca20-9c48-4066-9e50-c5d25c50f0d1.png" alt="UnfoldBIDS.jl Logo"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldDecode.jl"><img src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277622487-802002c0-a1f2-4236-9123-562684d39dcf.png" alt="UnfoldDecode.jl Logo"></a>|<a href="https://github.com/unfoldtoolbox/UnfoldStats.jl"><img  src="https://github-production-user-asset-6210df.s3.amazonaws.com/10183650/277623799-4c8f2b5a-ea84-4ee3-82f9-01ef05b4f4c6.png" alt="UnfoldStats.jl Logo"></a>|<a href=""><img src="https://github.com/user-attachments/assets/ffb2bba6-3a30-48b7-9849-7d4e7195b297" alt="UnfoldMixedModels.jl logo"></a>|

A toolbox for visualizations of EEG/ERP data and Unfold.jl models.

<img  src="https://raw.githubusercontent.com/unfoldtoolbox/UnfoldMakie.jl/8plots3/docs/src/assets/complex_plot.png" width="300" align="right">
<p align="center">
  <img src="docs/build/assets/UM_plots.gif" width="300" align="right">
</p>
Based on two libraries:
- [Makie.jl](https://makie.juliaplots.org/stable/) - very flexible visualisation library ([Maki-e](https://en.wikipedia.org/wiki/Maki-e) means "visualisation" on Japanese);
- [AlgebraOfGraphics.jl](https://github.com/MakieOrg/AlgebraOfGraphics.jl) - Makie-based grammar of graphics visualisation library, allowing flexible mapping. 

Additionally we provide some specific plots for:
- [Unfold.jl](https://github.com/unfoldtoolbox/unfold.jl/) - for performing rERP analyses;
But `Unfold.jl` is not a dependency and all plotting functions are **agnostic** to any specific analysis package.

This package offers users high performance, and highly customizable plots.

We currently support 9 general ERP plots: 
- ![icon_erpplot_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/22c8472d-df78-46d7-afe8-e1e4e7b04313)
ERP plots
- ![icon_butterfly_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/30b86665-3705-4258-bffa-97abcd308235)
Butterfly plots
- ![icon_topoplot_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/ea91f14f-30df-4316-997b-56bc411c9276)
Topography plots
- ![icon_toposeries_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/eceab5d6-88c7-41ae-b0d8-5ca652e83b40)
Topography time series
- ![icon_erpgrid_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/83b42a21-439a-49fd-80bc-cd82872695e9)
ERP grid
- ![icon_erpimage_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/b45b0547-7333-4d28-9ac8-33a989b7c132)
ERP images
- ![icon_channelimage_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/7ea16a7a-879a-4dcc-aaab-bc97211910ba)
Channel images
- ![icon_parallel_20px](https://github.com/unfoldtoolbox/UnfoldMakie.jl/assets/10183650/dab097c3-bcd6-4405-a44b-71cbe3e5fac9)
Parallel coordinates
- Circular topoplots

And 2 Unfold-specific plots:
- Design matrices
- Splines plot

### Installing Julia

<details>
<summary>Click to expand</summary>

The recommended way to install julia is [juliaup](https://github.com/JuliaLang/juliaup).
It allows you to, e.g., easily update Julia at a later point, but also to test out alpha/beta versions etc.

TLDR: If you don't want to read the explicit instructions, just copy the following command

#### Windows

AppStore -> JuliaUp,  or `winget install julia -s msstore` in CMD

#### Mac & Linux

`curl -fsSL https://install.julialang.org | sh` in any shell
</details>

### Installing UnfoldMakie.jl

```julia
using Pkg
Pkg.add("UnfoldMakie")
```

## Quickstart

```julia
using UnfoldMakie
using CairoMakie # backend
using Unfold, UnfoldSim # Fit / Simulation

data, evts = UnfoldSim.predef_eeg(; noiselevel = 12, return_epoched = true)
data = reshape(data, 1, size(data)...) # simulate a single channel

times = range(0, step = 1 / 100, length = size(data, 2))
m = fit(UnfoldModel, @formula(0 ~ 1 + condition), evts, data, times)

plot_erp(coeftable(m))
```

## Contributions

Contributions are very welcome. These can be typos, bug reports, feature requests, speed improvements, new solvers, better code, better documentation.

### How to Contribute

You are very welcome to submit issues and start pull requests!

### Adding Documentation

1. We recommend to write a Literate.jl document and place it in `docs/literate/FOLDER/FILENAME.jl` with `FOLDER` being `HowTo`, `Explanation`, `Tutorial` or `Reference` ([recommended reading on the 4 categories](https://documentation.divio.com/)).
2. Literate.jl converts the `.jl` file to a `.md` automatically and places it in `docs/src/generated/FOLDER/FILENAME.md`.
3. Edit [make.jl](https://github.com/unfoldtoolbox/Unfold.jl/blob/main/docs/make.jl) with a reference to `docs/src/generated/FOLDER/FILENAME.md`.

## Citation

If you use these visualizations, please cite:


[![DOI](https://joss.theoj.org/papers/10.21105/joss.07560/status.svg)](https://doi.org/10.21105/joss.07560) - this is our publication in *Journal of Open Source Software* on version 0.5.11. We recommend to cite this paper.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14500860.svg)](https://doi.org/10.5281/zenodo.14192333) - this is DOI of the last version of UM.jl. Cite this or others DOIs if you need to mention specific version of the package. 

## Contributors
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://www.benediktehinger.de"><img src="https://avatars.githubusercontent.com/u/10183650?v=4?s=100" width="100px;" alt="Benedikt Ehinger"/><br /><sub><b>Benedikt Ehinger</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/issues?q=author%3Abehinger" title="Bug reports">🐛</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=behinger" title="Code">💻</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=behinger" title="Documentation">📖</a> <a href="#ideas-behinger" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-behinger" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#maintenance-behinger" title="Maintenance">🚧</a> <a href="#question-behinger" title="Answering Questions">💬</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/pulls?q=is%3Apr+reviewed-by%3Abehinger" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=behinger" title="Tests">⚠️</a> <a href="#tutorial-behinger" title="Tutorials">✅</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/vladdez"><img src="https://avatars.githubusercontent.com/u/33777074?v=4?s=100" width="100px;" alt="Vladimir Mikheev"/><br /><sub><b>Vladimir Mikheev</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/issues?q=author%3Avladdez" title="Bug reports">🐛</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=vladdez" title="Code">💻</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=vladdez" title="Documentation">📖</a> <a href="#ideas-vladdez" title="Ideas, Planning, & Feedback">🤔</a> <a href="#maintenance-vladdez" title="Maintenance">🚧</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/pulls?q=is%3Apr+reviewed-by%3Avladdez" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=vladdez" title="Tests">⚠️</a> <a href="#tutorial-vladdez" title="Tutorials">✅</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Link250"><img src="https://avatars.githubusercontent.com/u/4541950?v=4?s=100" width="100px;" alt="Quantum"/><br /><sub><b>Daniel Baumgartner</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=Link250" title="Code">💻</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=Link250" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/NiklasMGaertner"><img src="https://avatars.githubusercontent.com/u/54365174?v=4?s=100" width="100px;" alt="NiklasMGaertner"/><br /><sub><b>Niklas Gärtner</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=NiklasMGaertner" title="Code">💻</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=NiklasMGaertner" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/SorenDoring"><img src="https://avatars.githubusercontent.com/u/54365184?v=4?s=100" width="100px;" alt="SorenDoring"/><br /><sub><b>Soren Doring</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=SorenDoring" title="Code">💻</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=SorenDoring" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lokmanfl"><img src="https://avatars.githubusercontent.com/u/44772645?v=4?s=100" width="100px;" alt="lokmanfl"/><br /><sub><b>Fadil Furkan Lokman</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=lokmanfl" title="Code">💻</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=lokmanfl" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jschepers"><img src="https://avatars.githubusercontent.com/u/22366977?v=4?s=100" width="100px;" alt="Judith Schepers"/><br /><sub><b>Judith Schepers</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/issues?q=author%3Ajschepers" title="Bug reports">🐛</a> <a href="#ideas-jschepers" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=jschepers" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://reneskukies.de/"><img src="https://avatars.githubusercontent.com/u/57703446?v=4?s=100" width="100px;" alt="René Skukies"/><br /><sub><b>René Skukies</b></sub></a><br /><a href="https://github.com/unfoldtoolbox/UnfoldMakie.jl/commits?author=ReneSkukies" title="Documentation">📖</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

## Acknowledgements

Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – Project-ID 251654672 – TRR 161” / “Gefördert durch die Deutsche Forschungsgemeinschaft (DFG) – Projektnummer 251654672 – TRR 161.

Funded by Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) under Germany´s Excellence Strategy – EXC 2075 – 390740016


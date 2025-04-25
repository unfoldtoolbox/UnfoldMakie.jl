```@meta
CurrentModule = UnfoldMakie
```
# UnfoldMakie.jl Documentation
Welcome to [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl): a Julia package for visualizations of EEG/ERP data and Unfold.jl models.

```@raw html
<div style="width:100%; margin: auto;">
  <img src="docs/build/assets/UM_plots.gif" width="300">
</div>
```
![](docs/build/assets/UM_plots.gif)

![Visualization of EEG data](https://github.com/unfoldtoolbox/UnfoldMakie.jl/raw/main/docs/build/assets/UM_plots.gif)

## Key features 
- 🎯 **Focused**: Specialized for (r)ERP visualization — simpler than EEGLAB, MNE, etc.
- 🎨 **Customizable**: Full control over colors, lines, layouts via Makie.jl flexibility.
- ⚡ **Fast**: Complex figures (e.g., 50 topoplots) generated ~20× faster than EEGLAB.
- 🔄 **Interactive**: Built-in support for Observables.jl, enabling dynamic plots.
- 🗺️ **Smart aesthetics**: Scientific color maps by default (no misleading rainbows!).
- 📚 **Well-documented**: Extensive examples and user guides.

For more highlights visit [this page](@ref features).

## Installation 
```julia-repl
julia> using Pkg; Pkg.add("UnfoldMakie")
```
For more detailed instructions please refer to [Installing Julia & Unfold Packages](https://unfoldtoolbox.github.io/UnfoldDocs/main/installation/).


## Usage example
Start with ERP plot and topopplot series. 
```@example erp
using UnfoldMakie, CairoMakie, Unfold
results = Unfold.coeftable(UnfoldMakie.example_data("UnfoldLinearModel"))
plot_erp(
    results,
    mapping = (; col = :coefname, color = :coefname => "Conditions"),
    axis = (; xlabel = "Time [s]"),
)
```

```@example topoplot_series
using UnfoldMakie, CairoMakie
dat, positions = UnfoldMakie.example_data()
plot_topoplotseries(
    dat; bin_num = 16, nrows = 4,
    positions = positions,
    visual = (; label_scatter = false, contours = false),
    axis = (; xlabel = "Time windows [s]"),
)
```


## Where to start: Learning roadmap
### 1. First step
📌 Goal: Check why we need multiple plot types for Event-related potentials and what kind of plot types exist. 
🔗 [Plot types](@ref) | [Complex figures](@ref)

### 2. Intermediate topics
📌 Goal: Check the most popular plots.
🔗 [ERP plot](@ref erp_vis) | [Topoplot](@ref topo_vis)

### 3. Advanced topics
📌 Goal: Learn about advanced customization
🔗 [Visualize uncertainty in topoplot series](@ref)


## Statement of need

UnfoldMakie.jl is a Julia package for visualization of electroencephalography (EEG) data, with a focus on event-related potentials (ERPs) and regression-ERPs (rERPs). UnfoldMakie.jl fills a gap as one of the only dedicated EEG visualization libraries and offers ease of use, customization, speed, and detailed documentation. It allows for both explorative analysis (zooming/panning) and export to publication-ready vector graphics. This is achieved via multiple backends of [Makie.jl](https://makie.juliaplots.org/): vector graphics with **CairoMakie.jl**, GPU-accelerated interactive graphics with **GLMakie.jl**, and the browser-based **WGLMakie.jl**.

In an earlier study ([Mikheev et al., 2024](#)), we asked novice and expert practitioners for insights into their ERP visualization practices. The results of this survey were used to develop and improve UnfoldMakie.jl. Further, UnfoldMakie.jl is agnostic (independent) of any specific analysis framework, but it nicely accompanies the rERP analysis package [**Unfold.jl**](https://github.com/unfoldtoolbox/Unfold.jl) ([Ehinger & Dimigen, 2019](https://peerj.com/articles/7838/)).

The target audience of this package is anyone working with EEG, MEG, ERP, iEEG or other time-series data.

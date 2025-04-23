```@meta
CurrentModule = UnfoldMakie
```
# UnfoldMakie.jl Documentation
Welcome to [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl)

```@raw html
<div style="width:60%; margin: auto;">

</div>
```

## Installation 
```julia-repl
julia> using Pkg; Pkg.add("UnfoldMakie")
```
For more detailed instructions please refer to [Installing Julia & Unfold Packages](https://unfoldtoolbox.github.io/UnfoldDocs/main/installation/).

## Usage example
Start with simple plots
```@example quickstart
using UnfoldMakie
using DataFrames
using TopoPlots

dat, positions = TopoPlots.example_data();
df = DataFrame(:estimate => dat[:, 340, 1])
plot_topoplot(df; positions = positions, axis = (; xlabel = "340 ms"), colorbar = (; height = 350),)
```

... and master complicated ones!

```@raw html
<img src="assets/complex_plot.png" width="300" align="right"/>
```

## Key features 

- **Focused.** [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) focuses exclusively on visualizing (r)ERPs, unlike other toolboxes such as [EEGLAB](https://sccn.ucsd.edu/eeglab/), [FieldTrip](https://www.fieldtriptoolbox.org/), `Brainstorm`, or [MNE](http://mne.tools). This makes it easier to understand, use, and maintain the package in the future.

- **Customizable.** The majority of EEG researchers perceive the flexibility of coding as the most important feature of the EEG toolbox. Consequently, users [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) have great flexibility in customizing most aspects of the plots, such as colors, line styles, and axis decorations. 

- **Combining plots** The layout system for subplots in `Makie.jl` makes it easy to combine and align various plot types.
- **Flexible mapping.** With [AlgebraOfGraphics.jl](https://aog.makie.org/), it is easy to map conditions, groups, channels, or other features, to a large variety of aesthetics like linestyle, color, marker and others. It works similar to the popular R package [ggplot2](https://ggplot2.tidyverse.org/).

- **Flexible data input.** All functions support basic `Arrays` and tidy `DataFrames`.

- **Fast.** Julia and `Makie.jl` allows fast plotting of figures with very complex layout. As an example, it is able to plot one figure with 50 topoplots in 1.9 seconds (1.6 sec with DelaunayMesh interpolation), which is ~20 times faster, compared to [EEGLAB](https://sccn.ucsd.edu/eeglab/). Although, the Python-based [MNE](http://mne.tools) is faster by one second. For more details check [this page](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev/generated/intro/speed/)

- **Faster updating.** `Makie.jl` is incredibly fast at updating figures, which is beneficial for developing interactive tools and creating animations. [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) can create and save a topoplot gif file with 50 frames in 1.7 times less time than [MNE](http://mne.tools) (Table 2).

- **Interactive.** Several plots in our package have interactive features. They are supported by `Observables.jl`, which allows for fast data exchange and quick plot updating.

- **Scientific color maps.** According to our previous study [(Mikheev, 2024)](https://apertureneuro.org/article/116386-the-art-of-brainwaves-a-survey-on-event-related-potential-visualization-practices), 40% of EEG researchers are not aware of the issue of perceptually non-uniform color maps. [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) uses scientific color maps throughout.

- **Documented.** There is extensive documentation with many usage examples and docstrings.



## Where to start: Learning roadmap
### 1. First step
📌 Goal: Check why we need multiple plot types for Event-related potentials and what kind of plot types exist. 
🔗 [Plot types](@ref) | [Include multiple figures in one](@ref)

### 2. Intermediate topics
📌 Goal: Check the most popular plots.
🔗 [ERP plot](@ref) | [Topoplot](@ref)

### 3. Advanced topics
📌 Goal: Learn about advanced customization
🔗 [Visualize uncertainty in topoplot series](@ref)



## Statement of need

UnfoldMakie.jl is a Julia package for visualization of electroencephalography (EEG) data, with a focus on event-related potentials (ERPs) and regression-ERPs (rERPs). UnfoldMakie.jl fills a gap as one of the only dedicated EEG visualization libraries and offers ease of use, customization, speed, and detailed documentation. It allows for both explorative analysis (zooming/panning) and export to publication-ready vector graphics. This is achieved via multiple backends of [Makie.jl](https://makie.juliaplots.org/): vector graphics with **CairoMakie.jl**, GPU-accelerated interactive graphics with **GLMakie.jl**, and the browser-based **WGLMakie.jl**.

In an earlier study ([Mikheev et al., 2024](#)), we asked novice and expert practitioners for insights into their ERP visualization practices. The results of this survey were used to develop and improve UnfoldMakie.jl. Further, UnfoldMakie.jl is agnostic (independent) of any specific analysis framework, but it nicely accompanies the rERP analysis package [**Unfold.jl**](https://github.com/unfoldtoolbox/Unfold.jl) ([Ehinger & Dimigen, 2019](https://peerj.com/articles/7838/)).

The target audience of this package is anyone working with EEG, MEG, ERP, iEEG or other time-series data.

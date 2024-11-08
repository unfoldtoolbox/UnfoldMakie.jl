---
title: '`UnfoldMakie.jl`: A Julia package for ERP visualization'

tags:
  - Julia
  - Event-related potentials
  - visualization
  - interactivity 
  - user study
authors:
  - name: Vladimir Mikheev
    orcid: 0000-0002-4738-6655
    equal-contrib: true
    affiliation: 1
  - name: Benedikt Ehinger
    orcid: 0000-0002-6276-3332
    equal-contrib: true
    affiliation: "1, 2"
affiliations:
 - name: University of Stuttgart, Institute for Visualization and Interactive Systems, Germany
   index: 1
 - name: University of Stuttgart, Stuttgart Center for Simulation Science, Germany
   index: 2

date: 30 October 2024
bibliography: paper.bib

---


= Statement of need

`UnfoldMakie.jl` is a Julia package for visualization of electroencephalography (EEG) data, with a focus on event-related potentials (ERPs) and regression-ERPs (rERPs). `UnfoldMakie.jl` fills a gap as one of the only dedicated EEG visualization libraries and offers ease of use, customization, speed, and detailed documentation. It allows for both explorative analysis (zooming/panning) and export to publication-ready vector graphics. This is achieved via multiple backends of `Makie.jl` @danisch2021makie: vector graphics with `CairoMakie.jl`, GPU-accelerated interactive graphics with `GLMakie.jl` and the browser-based `WGLMakie,jl`. 

In an earlier study @mikheev2024art, we asked novice and expert practitioners for insights into their ERP visualization practices. The results of this survey were used to develop and improve `UnfoldMakie.jl`. Further, `UnfoldMakie.jl` is agnostic (independent) of any specific analysis framework, but it nicely accompanies the rERP analysis package `Unfold.jl` @ehinger2019unfold.

The target audience of this package is anyone working with EEG, MEG, ERP, iEEG or other time-series data.

= Functionality
`UnfoldMakie.jl` excels in various fields:
- Focused. `UnfoldMakie.jl` focuses exclusively on visualizing (r)ERPs, unlike other toolboxes such as `EEGLAB`, `FieldTrip`, `Brainstorm`, or `MNE`. This makes it easier to understand, use, and maintain the package in the future.
- Customizable. The majority of EEG researchers perceive the flexibility of coding as the most important feature of the EEG toolbox @mikheev2024art. Consequently, users `UnfoldMakie.jl` have great flexibility in customizing most aspects of the plots, such as colors, line styles, and axis decorations. 
- Combining plots. The layout system for subplots in `Makie.jl` makes it easy to combine and align various plot types.
- Flexible mapping. With `AlgebraOfGraphics.jl`, it is easy to map conditions, groups, channels, or other features, to a large variety of aesthetics like linestyle, color, marker and others. It works similar to the popular R package `ggplot2`.
- Flexible data input. All functions support basic `Arrays` and tidy `DataFrames`.
- Fast. Julia and `Makie.jl` allows fast plotting of figures with very complex layout. As an example, it is able to plot one figure with 50 topoplots in 1.9 seconds (1.6 sec with DelaunayMesh interpolation), which is ~20 times faster, compared to `EEGLAB`. Although, the Python-based `MNE` is faster by one second. #footnote[The measurements were done by using `BenchmarkTools.jl`. @BenchmarkTools.jl-2016 Be aware that results of benchmarking can vary each run and depends on a OS, package environment, other processes running on computer etc.]
- Faster updating. `Makie.jl` is incredibly fast at updating figures, which is beneficial for developing interactive tools and creating animations. `UnfoldMakie.jl` can create and save a topoplot gif file with 50 frames in 1.7 times less time than `MNE`.
- Interactive. Several plots in our package have interactive features. They are supported by `Observables.jl`, which allows for fast data exchange and quick plot updating.
- Scientific color maps. According to our previous study @mikheev2024art, 40% of EEG researchers are not aware of the issue of perceptually non-uniform color maps. `UnfoldMakie.jl` uses scientific color maps throughout @crameri2020misuse @moreland2015we.
- Documented. There is extensive documentation with many usage examples and docstrings @Documenter_jl.


#figure(
  table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Languages*], [*Package*], [*Median speed*]
  ),
    [MATLAB],
    [EEGLAB],
    [36 sec],
    [Julia],
    [UnfoldMakie],
    [1.998 sec],
    [Python],
    [MNE],
    [0.826 sec]
),
  caption: [Benchmark for a topoplot series with 50 topolots],
)

#figure(
  table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Languages*], [*Package*], [*Median speed*]
  ),
    [Julia],
    [UnfoldMakie (.gif)],
    [5.801 sec],
    [Python],
    [MNE (.gif)],
    [9.494 sec]
),
  caption: [Benchmark for generating (and saving) of a topoplot animation  with 50 timepoints. No similar functionality exists in `EEGLAB`],
)

We currently support nine general EEG plot types (Figure 1) 
and two Unfold-specific plots: Design matrices and Spline plots.

#figure(
  image("complex_plot.png", width: 80%),
  caption: [8 plots generated by `UnfoldMakie.jl`. A) ERP plot, B) Butterfly plot, C) Topoplot, D) Topoplot timeseries, E) ERP image @jung1998analyzing, G) Channel image, H) Parallel coordinate plot @ten2006design.],
) <glacier>

= State of the field

There are dozens of libraries in Python and MATLAB for ERP analysis and visualization. According to a recent survey @mikheev2024art, most EEG practitioners (82%) have experience with MATLAB-based tools like `EEGLAB` @delorme2004eeglab, `FieldTrip` @oostenveld2011fieldtrip, `ERPLAB` @lopez2014erplab and Brainstorm @tadel2019meg. The Python-based `MNE` @Gramfort_MEG_and_EEG_2013 (41%) and the commercial software `Brain Vision Analyzer` (22%) further showed strong popularity. None of these toolboxes focuses particularly on visualizations. Indeed in terms of specialized EEG visualization toolboxes, we are aware of only two such libraries, both MATLAB-based and both named `eegvis` @robbins2012eegvis and @ehigner_2018eegvis. 

Few EEG/ERP analysis and/or visualization libraries have been written in Julia. We are aware of `NeuroAnalyzer.jl` @Wysokinski_NeuroAnalyzer, `EEGToolkit.jl` @Pereyra_EEGToolkit, `Neuroimaging.jl` @Luke_Neuroimaging. There are also #link("https://julianeuro.github.io/packages")[traces] of several abandoned projects. Worth highlighting is `PyMNE.jl`, a wrapper for the Python-MNE toolbox. 

However, all these packages are focused on the analysis of EEG data, while our package is specialized on the visualization of ERPs and rERPs. This is the gap that `UnfoldMakie.jl` fills.



= Funding
Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – Project-ID 251654672 – TRR 161 and in the Emmy Noether Programme - Project-ID 538578433.

= Acknowledgements

We acknowledge contributions from Daniel Baumgartner, Niklas Gärtner, Soren Doring, Fadil Furkan Lokman, Judith Schepers, and René Skukies. 

= Toolbox dependencies
`Makie.jl` @danisch2021makie, 
`AlgebraOfGraphics.jl` @Krumbiegel_AlgebraOfGraphics, 
`TopoPlots.jl`

#bibliography("paper.bib")



# UnfoldMakie Documentation

```@raw html
<img src="assets/complex_plot.png" width="300" align="right"/>
```

This is the documentation of the UnfoldMakie.jl package for the Julia programming language. 

## Highlights of UnfoldMakie.jl

- **10 plot functions for displaying ERPs.**
Each plot emphasizes certain dimensions while collapsing others.
- **Fast plotting**
Plot one figure with 20 topoplots in 1 second? No problemo!
- **Highly adaptable.**
The package is primarily based on [Unfold.jl](https://github.com/unfoldtoolbox/unfold.jl/) and [Makie.jl](https://makie.juliaplots.org/stable/).
- **Many usage examples**
You can find many user-friendly examples of how to use and adapt the plots in this documentation.
- **Scientific colormaps by default**
According to our study [(Mikheev, 2024)](https://apertureneuro.org/article/116386-the-art-of-brainwaves-a-survey-on-event-related-potential-visualization-practices), 40% of EEG researchers do not know about the issue of scientific color maps. By default, we use `Reverse(:RdBu)` (based on [colorbrewer](https://colorbrewer2.org/#type=sequential&scheme=BuGn&n=3)) and `Roma` (based on [Sceintific Colormaps](https://www.fabiocrameri.ch/colourmaps/) by Fabio Crameri) as default color maps. 
- **Interactivity** 
Several plots make use of `Observables.jl` which allows fast updating of the underlying data. Several plots already have predefined interactive features, e.g. you can click on labels to enable / disable them. See `plot_topoplotseries` and `plot_erpimage` for examples.

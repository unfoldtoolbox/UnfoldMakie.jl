# # [Features of UnfoldMakie.jl](@id features)
# Or why this package is cool and you should use it.
#
# - **Focused.** [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) focuses exclusively on visualizing (r)ERPs, unlike other toolboxes such as 
# [EEGLAB](https://sccn.ucsd.edu/eeglab/), [FieldTrip](https://www.fieldtriptoolbox.org/), `Brainstorm`, or [MNE](http://mne.tools). 
# This makes it easier to understand, use, and maintain the package in the future.
#
# - **Customizable.** The majority of EEG researchers perceive the flexibility of coding as the most important feature of the EEG toolbox. 
# Consequently, users of [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) have great flexibility in customizing most aspects of the plots, 
# such as colors, line styles, and axis decorations.
#
# - **Combining plots.** The layout system for subplots in `Makie.jl` makes it easy to combine and align various plot types.
#
# - **Flexible mapping.** With [AlgebraOfGraphics.jl](https://aog.makie.org/), it is easy to map conditions, groups, channels, or other features 
# to a large variety of aesthetics like linestyle, color, marker, and others. 
# It works similarly to the popular R package [ggplot2](https://ggplot2.tidyverse.org/).
#
# - **Flexible data input.** All functions support basic `Arrays` and tidy `DataFrames`.
#
# - **Fast.** Julia and `Makie.jl` allow fast plotting of figures with very complex layouts. 
# For example, it can plot one figure with 50 topoplots in 1.9 seconds (1.6 sec with DelaunayMesh interpolation), 
# which is approximately 20 times faster compared to [EEGLAB](https://sccn.ucsd.edu/eeglab/). 
# (Although the Python-based [MNE](http://mne.tools) is faster by one second.) 
# For more details, see [this page](https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev/generated/intro/speed/).
#
# - **Faster updating.** `Makie.jl` is incredibly fast at updating figures, 
# which is beneficial for developing interactive tools and creating animations. 
# [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) can create and save a topoplot gif file with 50 frames 
# in 1.7 times less time than [MNE](http://mne.tools) (Table 2).
#
# - **Interactive.** Several plots in our package have interactive features. 
# They are supported by `Observables.jl`, which allows for fast data exchange and quick plot updating.
#
# - **Scientific color maps.** According to our previous study [(Mikheev, 2024)](https://apertureneuro.org/article/116386-the-art-of-brainwaves-a-survey-on-event-related-potential-visualization-practices), 
# 40% of EEG researchers are not aware of the issue of perceptually non-uniform color maps. 
# [UnfoldMakie.jl](https://github.com/unfoldtoolbox/UnfoldMakie.jl) uses scientific color maps throughout.
#
# - **Documented.** There is extensive documentation with many usage examples and docstrings.

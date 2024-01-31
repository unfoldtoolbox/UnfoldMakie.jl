# [Plot Types](@id plot_types)

# # The Dilemma of Multidimensionality

#=
EEG (electroencephalography) – we measure your brain electricity to know what you are thinking
ERP (event-related potential) – how stimulus affects the electrode’s voltage

EEG – multidimensional data and could be presented differently.

Possible dimensions:
- Voltage (must have)
- Time
- Number of channels (1-128)
- Spatial layout of channels
- Experimental conditions
- Trials/subjects
=#

# <img src="../../src/assets/slicing.jpg" width="128"/>

#=
Each way of ERP presentation is a choice of dimensions.
Hard to show meaningfully more than 3 dimensions.
=#

# # Plot types

# Each plot type can represent several dimensions. Here we represented 8 plot types.
# <img src="../../src/assets/dimensions.jpg" width="128"/>

# If you want to know more about how we come up with these plot types, please read the paper [The Arte of Brainwaves](https://www.biorxiv.org/content/10.1101/2023.12.20.572507v2.full)

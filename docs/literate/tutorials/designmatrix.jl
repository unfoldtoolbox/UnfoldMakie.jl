# # Design matrix

# **Design matrix plot** is a visualization type used to inspect the structure of predictors in EEG regression analysis. It fully represents the *trials* and *predictors* dimensions using a colored grid (heatmap). Each row corresponds to a trial, and each column to a predictor, with color intensity reflecting the predictor’s value.

# Unlike ERP or butterfly plots that focus on time and channel dimensions, the design matrix plot focuses on the underlying experimental design. It gives a compact, at-a-glance overview of how predictors vary across trials 🧩.

# Options like `sort_data` and `standardize_data` enhance interpretability by reorganizing trials or normalizing predictor scales. This type of plot is essential for checking data integrity before model fitting.

# # Setup
# **Package loading**

using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie

# **Data**
uf = UnfoldMakie.example_data("UnfoldLinearModel");

# # Plot Design Matrices

# The following code will result in the default configuration. 

plot_designmatrix(designmatrix(uf))

# To make the design matrix easier to read, you may want to sort it using `sort_data`.

plot_designmatrix(designmatrix(uf); sort_data = true)

# # Configurations for Design matrix plot

# ```@docs
# plot_designmatrix
# ```

# # Adding labels to topoplots

using CairoMakie, TopoPlots, MakieThemes
using UnfoldMakie, CSV

# You ned 3 things to add labels to topoplots: list of labels, list of positions, and the data.
# We have some predefined data:
topo_array, topo_positions = TopoPlots.example_data()
l64, pos64 = example_montage("biosemi_64")

plot_topoplot(
        topo_array[:, 100, 1];
        labels = l64,
        positions = pos64,
        visual = (; label_text = true),
        axis = (; xlabel = "100 ms"),
    )

# In internet you can find various standard montages with channel labels.
# For instance, lables and position of [standard_1005_2D](https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv).
# [Here](https://github.com/mne-tools/mne-python/tree/main/mne/channels/data/montages) you can find many others.


# # Adding labels to topoplots

using TopoPlots, MakieThemes
using UnfoldMakie, UnfoldSim

# You ned 3 things to add labels to topoplots: list of labels, list of positions, and the data.

# In internet you can find various standard montages with channel labels.
# For instance, lables and position of [standard_1005_2D](https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv).
# [Here](https://github.com/mne-tools/mne-python/tree/main/mne/channels/data/montages) you can find many others.
# But you also need to find the corresponding data for them!

# We have some predefined data with 227 channels:

df_toposeries, pos_toposeries, lab_toposeries = UnfoldMakie.example_data("bootstrap_toposeries"; noiselevel = 7);
df_trial1_t50 = filter(row -> row.trial == 1 && row.time == 50, df_toposeries)

plot_topoplot(
    df_trial1_t50.estimate;
    labels = lab_toposeries,
    positions = pos_toposeries,
    visual = (; label_text = true, enlarge = 0.5, label_scatter = false),
    axis = (; xlabel = "100 ms", limits = ((0, 1), (0, 0.9))),
)

# Imagine we want only 64 channels. In that case, we need to find which of the 227 channels correspond to the 64 channels in the montage.
# For that let's use the 64 channles names from biosemi montage (also stored):
l64, _ = example_montage("biosemi_64")

# Let's filter out this labels from the full data with 227 stored in [HArtMuT headmodel](https://hartmut.neuro.tu-berlin.de/#about):
hart = headmodel()
filter_idx = findall(l -> l in l64, hart.electrodes["label"])

labels_64 = hart.electrodes["label"][filter_idx]  # ordered as in data
estimates_64 = df_trial1_t50.estimate[filter_idx]
positions_64 =
    hart.electrodes["pos"] |>
    x -> to_positions(x') |>
    x -> [UnfoldMakie.Point2f(p[1] + 0.5, p[2] + 0.5) for p in x] |>
    x -> x[filter_idx];

plot_topoplot(
    estimates_64;
    labels = labels_64,
    positions = positions_64,
    visual = (; label_text = true),
    axis = (; xlabel = "100 ms"),
)


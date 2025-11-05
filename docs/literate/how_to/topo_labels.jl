# # [Adding labels to topoplot channels](@ref topo_labels)

using TopoPlots
using CairoMakie, MakieThemes
using UnfoldMakie, UnfoldSim

# You need 3 vectors to add labels to topoplots: of channel labels, of channel positions, and of voltage estimates.

# On the internet, you can find various standard montages with channel labels.
# For instance, see the labels and positions of [standard_1005_2D](https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv).
# You can find many others [here](https://github.com/mne-tools/mne-python/tree/main/mne/channels/data/montages).
# But make sure you also have the corresponding data for them!

# In our case, we have predefined data with 227 channels:

df_toposeries, pos_toposeries, lab_toposeries = UnfoldMakie.example_data("bootstrap_toposeries"; noiselevel = 7);
df_trial1_t50 = filter(row -> row.trial == 1 && row.time == 50, df_toposeries)

plot_topoplot(
    df_trial1_t50.estimate;
    labels = lab_toposeries,
    positions = pos_toposeries,
    visual = (; label_text = true, enlarge = 0.5, label_scatter = false),
    axis = (; xlabel = "50 ms", limits = ((0, 1), (0, 0.9))),
)

# Imagine we want only 64 channels. In that case, we need to find which of the 227 channels correspond to the 64 channels in the montage.
# For that, let's use the 64 channel names from the BioSemi montage (also predefined):

l64, _ = example_montage("biosemi_64")

# Let's extract these 64 labels from the full 227-channel dataset provided by the [HArtMuT head model](https://hartmut.neuro.tu-berlin.de/#about):
hart = headmodel()
filter_idx = findall(l -> l in l64, hart.electrodes["label"])

labels_64 = hart.electrodes["label"][filter_idx]
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
    axis = (; xlabel = "50 ms"),
)

# Let's add some customizations:
with_theme(Theme(; fontsize = 18, fonts = (; regular = "Ubuntu Mono"))) do
    plot_topoplot(
        estimates_64;
        labels = labels_64,
        positions = positions_64,
        visual = (; label_text = true, colormap = :diverging_tritanopic_cwr_75_98_c20_n256, contours = false),
        axis = (; xlabel = "50 ms"),
    )
end
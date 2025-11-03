# # Setting electrode labels

using CairoMakie, TopoPlots, MakieThemes
using UnfoldMakie, CSV

# Changing fonts and font size

dat, positions = TopoPlots.example_data()
labels = ["s$i" for i = 1:size(dat, 1)]

# To get the positions from the labels we use a [database](https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv).


url = "https://raw.githubusercontent.com/sappelhoff/eeg_positions/main/data/Nz-T10-Iz-T9/standard_1005_2D.tsv"
pos_df = CSV.read(download(url), DataFrame)

# convert to Dict: name => (x, y)
pos_dict = Dict(row.label => (row.x, row.y) for row in eachrow(pos_df))
labels = ["Fp1", "Fz", "C3", "O2"]
positions = [UnfoldMakie.Point{2,Float32}(pos_dict[ch]...) for ch in channels]

# Real example with 10-20 channels
url = "https://github.com/mne-tools/mne-python/blob/main/mne/channels/data/montages/biosemi64.txt"
pos_df = CSV.read(download(url), DataFrame)
positions64 = [UnfoldMakie.Point{2,Float32}(pos_dict[ch]...) for ch in biosemi64]

positions = [pos_dict[ch] for ch in channels]
plot_topoplot(
        topo_array[:, 340, 1];
        labels = labels,
        positions = positions,
        visual = (; label_text = true),
        axis = (; xlabel = "340 ms"),
    )


plot_topoplot(
        topo_array[1:19, 340, 1];
        labels = TopoPlots.CHANNELS_10_20,
        positions = positions[1:19],
        visual = (; label_text = true),
        axis = (; xlabel = "340 ms"),
    )
    labels_64, positions_64 = UnfoldMakie.example_montage("montage_64")

    with_theme(Theme(; fontsize = 18, fonts = (; regular = "Ubuntu Mono"))) do
        plot_topoplot(
            topo_array[:, 100, 1];
            labels = labels_64,
            positions = topo_positions,
            visual = (; label_text = true),
            axis = (; xlabel = "340 ms"),
        )
    end
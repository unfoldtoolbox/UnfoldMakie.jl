# # [Adding labels to topoplot channels](@id topo_labels)

using TopoPlots
using CairoMakie, MakieThemes
using UnfoldMakie, UnfoldSim

# You need 3 vectors to add labels to topoplots: of channel labels, of channel positions, and of voltage estimates.
# Here we simulate all three vectors using Hartmut head model. 
# You can also use your own data and positions, but make sure they correspond to each other.

hart = Hartmut()
idx_64 = findall(l -> l in UnfoldMakie._labels_64, hart.electrodes["label"])
hart_estimate = hart.cortical["leadfield"][idx_64, 312, :] * [0.2, 0.4, 0.4]
positions_64 =
    hart.electrodes["pos"] |>
    x ->
        to_positions(x') |>
        x -> [UnfoldMakie.Point2f(p[1] + 0.5, p[2] + 0.5) for p in x] |>
            x -> x[idx_64];
labels_64 = hart.electrodes["label"][idx_64]
plot_topoplot(
    hart_estimate;
    labels = labels_64,
    positions = positions_64,
    visual = (; label_text = true, label_scatter = false),
    axis = (; xlabel = ""),
)
############


# Let's add some customizations:
with_theme(Theme(; fontsize = 18, fonts = (; regular = "Ubuntu Mono"))) do
    plot_topoplot(
        hart_estimate;
        labels = labels_64,
        positions = positions_64,
        visual = (;
            label_text = true,
            colormap = :diverging_tritanopic_cwr_75_98_c20_n256,
            contours = false,
        ),
        axis = (; xlabel = ""),
    )
end

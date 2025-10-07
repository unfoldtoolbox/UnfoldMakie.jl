# # Customizing channel labels

using CairoMakie, TopoPlots, MakieThemes
using UnfoldMakie

# Changing fonts and font size

dat, positions = TopoPlots.example_data()
labels = ["s$i" for i = 1:size(dat, 1)]

with_theme(Theme(; fontsize = 25, fonts = (; regular = "Ubuntu Mono"))) do
    plot_topoplot(
        dat[:, 340, 1];
        labels,
        positions,
        visual = (; label_text = true),
        axis = (; xlabel = "340 ms"),
    )
end

# But also check that the font you choose is available on your PC or GitHub.

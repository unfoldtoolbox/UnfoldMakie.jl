# Customizing channel labels
using CairoMakie, TopoPlots

# Changing fonts

dat, positions = TopoPlots.example_data()

labels = ["s$i" for i in 1:size(dat, 1)]

with_theme(Theme(; fontsize=25, fonts=(; regular="Courier New"))) do
        TopoPlots.eeg_topoplot(dat[:, 340, 1]; labels, label_text=true, positions, 
        axis=(aspect=DataAspect(),),
    )
end

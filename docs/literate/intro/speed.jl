# Speed measurement
using UnfoldMakie
using TopoPlots
using PyMNE
using PythonPlot

# Data input 
dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)));

# Topoplots

@time plot_topoplot(dat[:, 320, 1]; positions = positions)

posmat = collect(reduce(hcat, [[p[1], p[2]] for p in positions])')
pypos = Py(posmat).to_numpy()
pydat = Py(dat[:, 320, 1])

@time begin
    f = PythonPlot.figure()
    PyMNE.viz.plot_topomap(
        pydat,
        pypos,
        sphere = 1.1,
        extrapolate = "box",
        cmap = "RdBu_r",
        sensors = false,
        contours = 6,
    )
    f.show()
end

# Topoplot series
@time begin
    plot_topoplotseries(
        df;
        bin_num = 20,
        positions = positions,
        axis = (; xlabel = "Time windows [s]"),
    )
end




easycap_montage = PyMNE.channels.make_standard_montage("standard_1020")
ch_names = pyconvert(Vector{String}, easycap_montage.ch_names)[1:64]
info = PyMNE.create_info(PyList(ch_names), ch_types = "eeg", sfreq = 1)
info.set_montage(easycap_montage)
simulated_epochs = PyMNE.EvokedArray(Py(dat[:, :, 1]), info)

@time simulated_epochs.plot_topomap(1:0)

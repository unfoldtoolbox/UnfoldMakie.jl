# # Speed measurement
# Here we will compare the speed of plotting UnfoldMakie with MNE (Python) and EEGLAB (MATLAB).
#
# Three cases are measured: 
# - Single topoplot
# - Topoplot series with 50 topoplots
# - Topoplott animation with 50 timestamps
#
# Note that the results of benchmarking on your computer and on Github may differ. 
using UnfoldMakie
using TopoPlots
using PyMNE
using PythonPlot
using BenchmarkTools
using Observables
using CairoMakie

# Data input 
dat, positions = TopoPlots.example_data()
df = UnfoldMakie.eeg_array_to_dataframe(dat[:, :, 1], string.(1:length(positions)));

# # Topoplots

# UnfoldMakie.jl
@benchmark plot_topoplot(dat[:, 320, 1]; positions = positions)

# UnfoldMakie.jl with DelaunayMesh
@benchmark plot_topoplot(
    dat[:, 320, 1];
    positions = positions,
    topo_interpolation = (; interpolation = DelaunayMesh()),
)

# MNE
posmat = collect(reduce(hcat, [[p[1], p[2]] for p in positions])')
pypos = Py(posmat).to_numpy()
pydat = Py(dat[:, 320, 1])

@benchmark begin
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

# # Topoplot series

# Note that UnfoldMakie and MNE have different defaults for displaying topoplot series. 
# UnfoldMakie in `plot_topoplot` averages over time samples. 
# MNE in `plot_topopmap` displays single samples without averaging.
#
# UnfoldMakie.jl
@benchmark begin
    plot_topoplotseries(
        df;
        bin_num = 50,
        positions = positions,
        axis = (; xlabel = "Time windows [s]"),
    )
end

# MNE
easycap_montage = PyMNE.channels.make_standard_montage("standard_1020")
ch_names = pyconvert(Vector{String}, easycap_montage.ch_names)[1:64]
info = PyMNE.create_info(PyList(ch_names), ch_types = "eeg", sfreq = 1)
info.set_montage(easycap_montage)
simulated_epochs = PyMNE.EvokedArray(Py(dat[:, :, 1]), info)

@benchmark simulated_epochs.plot_topomap(1:50)

# MATLAB
#
# Running MATLAB on a GitHub Action is not easy. 
# So we benchmarked three consecutive executions (on a screenshot) on a server with an AMD EPYC 7452 32-core processor.
# Note that Github and the server we used for MATLAB benchmarking are two different computers, which can give different timing results.

# ```@raw html
# <img src="../../../assets/MATLAB_benchmarking.png" align="middle"/>
# ```


# # Animation 
# The main advantage of Julia is the speed with which the figures are updated.

timestamps = range(1, 50, step = 1)
framerate = 50

# UnfoldMakie with .gif

@benchmark begin
    f = Makie.Figure()
    dat_obs = Observable(dat[:, 1, 1])
    plot_topoplot!(f[1, 1], dat_obs, positions = positions)
    record(f, "topoplot_animation_UM.gif", timestamps; framerate = framerate) do t
        dat_obs[] = @view(dat[:, t, 1])
    end
end

# ![](topoplot_animation_UM.gif)

# MNE with .gif
# Note that due to some bugs in (probably) `CondaPkg` topoplot is blac and white. 
@benchmark begin
    fig, anim = simulated_epochs.animate_topomap(
        times = Py(timestamps),
        frame_rate = framerate,
        blit = false,
        image_interp = "cubic", # same as CloughTocher
    )
    anim.save("topomap_animation_mne.gif", writer = "ffmpeg", fps = framerate)
end

# ![](topomap_animation_mne.gif)

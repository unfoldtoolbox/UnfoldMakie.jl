# Speed measurement
using UnfoldMakie
using TopoPlots
using PyMNE
using PythonPlot
using BenchmarkTools

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
# UnfoldMakie.jl
@benchmark begin
    plot_topoplotseries(
        df;
        bin_num = 50,
        positions = positions,
        axis = (; xlabel = "Time windows [s]"),
    )
end

# UnfoldMakie.jl with DelaunayMesh
@benchmark begin
    plot_topoplotseries(
        df;
        bin_num = 50,
        positions = positions,
        topo_attributes = (; interpolation = DelaunayMesh()),
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
# At present, it is not possible to run MATLAB within a Julia environment on GitHub. As a result, we can only provide a screenshot of the program execution.

# ```@raw html
# <img src="../../../assets/MATLAB_benchmarking.png" align="middle"/>
# ```


# Animation 

dat_obs = Observable(dat[:, 1, 1])
timestamps = range(1, 5, step = 1)
f = Figure()
plot_topoplot!(f, dat_obs; positions = positions)

@benchmark record(
    f,
    "../../src/assets/topoplot_animation.mp4",
    timestamps;
    framerate = 1,
) do t
    dat_obs[] = dat[:, t, 1]
end


#```@raw html
#<video autoplay loop muted playsinline controls src="../../../assets/topoplot_animation.mp4" />
#```

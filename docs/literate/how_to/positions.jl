# #  Convert electrode positions from 3D to 2D
# Sometimes you have 3D montage but you need 2D montage. How to convert one to another? The function `to_positions` should help.

using UnfoldMakie
using CairoMakie
using TopoPlots
using PyMNE;

# # Get positions from MNE

# Generate an MNE structure [taken from mne documentation](https://mne.tools/0.24/auto_examples/visualization/eeglab_head_sphere.html)

biosemi_montage = PyMNE.channels.make_standard_montage("biosemi64")

# # Projecting from 3D montage to 2D
pos3d = hcat(values(pyconvert(Dict, biosemi_montage.get_positions()["ch_pos"]))...)
pos2d = to_positions(pos3d)

f = Figure(size = (600, 300))
scatter(f[1, 1], pos3d[1:2, :], axis = (title = "Dropping third dimension",))
scatter(f[1, 2], pos2d, axis = (title = "Projection form 3D to 2D",))
f
# As you can see, the "naive" transformation of simply dropping the third dimension does not really work (left). Instead, we have to project the channels onto a sphere and unfold it (right).

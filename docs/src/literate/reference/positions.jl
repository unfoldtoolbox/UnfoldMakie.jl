using UnfoldMakie
using TopoPlots
using PyMNE


# # get MNE-positions
# Generate a fake MNE structure
# [taken from mne documentation](https://mne.tools/0.24/auto_examples/visualization/eeglab_head_sphere.html)

biosemi_montage = PyMNE.channels.make_standard_montage("biosemi64")
n_channels = length(biosemi_montage.ch_names)
fake_info = PyMNE.create_info(ch_names=biosemi_montage.ch_names, sfreq=250.,
                            ch_types="eeg")
data = rand(n_channels,1) * 1e-6
fake_evoked = PyMNE.EvokedArray(data, fake_info)
fake_evoked.set_montage(biosemi_montage)

pos = UnfoldMakie.toPositions(fake_evoked)

# # project from 3D electrode locations to 2D
pos3d = hcat(values(pyconvert(Dict,biosemi_montage.get_positions()["ch_pos"]))...)

pos2 = to_positions(pos3d)
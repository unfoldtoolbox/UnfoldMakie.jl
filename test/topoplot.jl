using UnfoldMakie
using PyMNE
using GLMakie
raw = PyMNE.io.read_raw("/store/data/8bit/derivatives/logs_added/sub-001/eeg/sub-001_task-ContinuousVideoGamePlay_run-02_eeg.vhdr")
	
raw.set_channel_types(Dict(:AMMO=>"misc",:HEALTH=>"misc",:PLAYERX=>"misc",:PLAYERY=>"misc",:WALLABOVE=>"misc",:WALLBELOW=>"misc",:CLOSESTENEMY=>"misc",:CLOSESTSTAR=>"misc"))
raw.set_montage("standard_1020")

    
layout_from_raw = PyMNE.channels.make_eeg_layout(get_info(raw))
positions = layout_from_raw.pos
        
ix = sortperm(positions[:,2])
positions = positions[ix,:]
        
labels =raw.copy().pick(["eeg"]).ch_names
labels = labels[ix]
data2 = randn(size(positions,1)) .* 30
data = (1:size(positions,1))

using TimerOutputs
to2 = TimerOutput()
fi = Figure()
@time for k = 1:20

             @timeit to2 "$(k)" UnfoldMakie.topoplot(data,positions=positions,fig=fi[1,k])
             #to= merge(to,to2)
        
        
end
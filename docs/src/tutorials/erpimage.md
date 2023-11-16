# [ERP Image Visualization](@id erpi_vis)

Here we discuss ERP image visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using CairoMakie
using UnfoldSim
include("../../example_data.jl")
```


## Plot ERP image

The following code will result in the default configuration. 
```@example main
data, evts = UnfoldSim.predef_eeg(; noiselevel=10, return_epoched=true)
plot_erpimage(data)
```

## Column Mappings for ERP image

Since ERP images use a `Matrix` as an input, the library does not need any informations about the mapping.

- `erpblur` (Number, `10`): number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module.
Non-Positive values deactivate the blur.
- `sortvalues` (bool, `false`): parameter over which plot will be sorted. Using sortperm() of Base Julia. 
    - sortperm() computes a permutation of the array's indices that puts the array into sorted order. 
- `meanplot` (bool, `false`): Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.

```@example main
plot_erpimage(data;
    meanplot = true,
    colorbar = (label = "Voltage [µV]",),
    visual = (colormap = :viridis, colorrange = (-40, 40)))

```

## Sorted ERP image

First, generate a data. Second, specify the necessary sorting parameter. 

```@example main
    dat, evts = UnfoldSim.predef_eeg(; 
        onset=LogNormalOnset(μ=3.5, σ=0.4), 
        noiselevel=5
    )
    dat_e, times = Unfold.epoch(dat, evts, [-0.1,1], 100)
    evts, dat_e = Unfold.dropMissingEpochs(evts, dat_e)
    evts.Δlatency =  diff(vcat(evts.latency, 0))
    dat_e = dat_e[1,:,:]

    plot_erpimage(times, dat_e; sortvalues=evts.Δlatency)
```
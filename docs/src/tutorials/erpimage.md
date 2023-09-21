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


## Plot ERP Images

The following code will result in the default configuration. 
```@example main
data, evts = UnfoldSim.predef_eeg(; noiselevel=10, return_epoched=true)
plot_erpimage(data)
```

## Column Mappings for ERP Images

Since ERP images use a `Matrix` as an input, the library does not need any informations about the mapping.

## extra=(;)
- erpBlur (number, 10) - Is a number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module. Negative values deactivate the blur.

- sortData (boolean, false) - Indicating whether the data is sorted; using sortperm() of Base Julia 
(sortperm() computes a permutation of the array's indices that puts the array into sorted order). 

- ploterp (bool, false) - Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data. If limits are set in the axis values both plots will be aligned.

```@example main
plot_erpimage(data;
    extra = (ploterp = true,),
    colorbar = (label = "Voltage [µV]",),
    visual = (colormap = :viridis, colorrange = (-40, 40)))

```

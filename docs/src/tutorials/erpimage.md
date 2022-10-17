# [ERP Image Visualization](@id erpi_vis)

Here we discuss ERP image visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

## Include used Modules
The following modules are necessary for following this tutorial:
```
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using CairoMakie
```

## Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 
!!! note
    We are working on UnfoldSim to generate sensible examples. Right now best is to use the test data of `erpcore-N170.jld2` from the [Load Data](@ref test_data) section.

Note that you do not need the pre-processing step detailed in that section.

## Plot ERP Images

The following code will result in the default configuration. 
```
plot_erpimage(dat_e[28,:,:])
```
At this point you can detail changes you want to make to the visualization through the plot config. These are detailed further below. 


![Default ERP Image](../images/erp_image_default.png)

## Column Mappings for ERP Images

Since ERP images use a `Matrix` as an input, the library does not need any informations about the mapping.

## Configurations for ERP Images

Here we look into possible options for configuring the ERP image visualization using `setExtraValues = (<name>=<value>,...)`.

For more general options look into the `Plot Configuration` section of the documentation.
This is the list of unique configuration (extraData):
- erpBlur (number)
- sortData (boolean)
- meanPlot (boolean)


### erpBlur (number)
Is a number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module. 
Default value is `10`. Negative values deactivate the blur.

### sortData (boolean)
Indicating whether the data is sorted; using sortperm() of Base Julia 
(sortperm() computes a permutation of the array's indices that puts the array into sorted order). 
Default is `false`.

### meanPlot (boolean)
Indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.
If limits are set in the axis values both plots will be aligned.

Default is `false`.


```
plot_erpimage(dat_e[28,:,:],
    setExtraValues = (meanPlot = true,),
    setColorbarValues = (label = "Voltage [µV]",),
    setVisualValues = (colormap = "Viridis", colorrange = (-40, 40)),

```

![ERP Image with Line](../images/erp_image_line.png)

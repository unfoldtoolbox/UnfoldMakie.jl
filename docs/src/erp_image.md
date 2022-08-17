## [General ERP Image Visualization](@id erpi_vis)

Here we discuss general butterfly plot visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

### Include used Modules
The following modules are necessary:
```@example main
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
using DataFramesMeta
using StatsBase
```
Note that `DataFramesMeta` is also used here in order to be able to use `@subset` for testing (filtering).
Note that `StatsBase` is also used here in order to be able to use `mean` in the following.

### Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

Use the test data of `erpcore-N170.jld2`.
Note that you do not need the pre-processing step detailed in that section.
Instead we extract some data as follows:
```@example main
erp_data = dat_e[:,:,evt_e.subject .==1]
```


### Configurations for ERP Images
```@example main
using Random
f = Figure()
sort_x = [[a[1] for a in argmax(erp_data[1,:,:],dims=2)]...]
@show typeof(sort_x)
image(f[1:4,1],erp_data[1,:,sort_x])
lines(f[5,1],mean(erp_data[1,:,:],dims=2)[:,1])
f
```
```@example main
image(mean(erp_data[1:30,:,:],dims=3)[:,:,1]')
```

### Plot ERP Images
This is how you finally plot the ERP image.

TODO LOOK

## TODO: MORE CONFIG DETAILS ONCE FINISHED
- is DataFramesMeta needed here?
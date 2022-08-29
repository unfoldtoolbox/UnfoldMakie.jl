## [General Parallel Coordinates Plot](@id pcp_vis)

Here we discuss general parallel coordinates plot (PCP) visualization. 
Make sure you have looked into the [installation instructions](@ref install_instruct).

### Include used Modules
The following modules are necessary for following this tutorial:
```
???
for effects?:
using PyMNE
using AlgebraOfGraphics
using RecipeBase
++
```

### Data
In case you do not already have data, look at the [Load Data](@ref test_data) section. 

Use the test data of `erpcore-N170.jld2`.

Some further definitions.
```
f = Figure()

data = effects(Dict(:category=>["face", "car"], :condition=>["intact"]), mres)

paraConfig = PlotConfig(:paracoord)

plot_paraCoord(data, paraConfig; channels=[1,7,6])
```

### Plot PCP Plots

The following code will result in the default configuration. 
```
paraConfig = PlotConfig(:paracoord)
```
[Here](@ref o_pcp_vis) we look into possible options for configuring the designmatrix visualization.
For more information on plot configurations in general, look at the [plot config](@ref plot_config) section. 

This is how you finally plot the PCP.
```
plot_paraCoord(data, paraConfig; channels=[1,7,6])
```

## TODO: USED MODULES, DATA?
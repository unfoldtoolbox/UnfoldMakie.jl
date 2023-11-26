# [Parallel Coordinates Plot](@id pcp_vis)
Here we discuss parallel coordinates plot (PCP) visualization. 

## Include used Modules
The following modules are necessary for following this tutorial:
```@example main
using Unfold
using UnfoldMakie
using DataFrames
using CairoMakie
```

## Data
```@example main
include("../../example_data.jl")
r1, positions = example_data();
r2 = deepcopy(r1)
r2.coefname .= "B" # we need a second category
r2.estimate .+= rand(length(r2.estimate))*0.1
results_plot = vcat(r1,r2);
nothing #hide
```

## Plot PCPs

```@example main
plot_parallelcoordinates(subset(results_plot,:channel=>x->x.<5); 
    mapping = (;color = :coefname))

```


## Normalization
Typically, parallelplots are normalized per axis (if that makes sense for channel x estimate, we dont know)

```@example main
f = Figure()
plot_parallelcoordinates(f[1,1],subset(results_plot,:channel=>x->x.<10); 
    mapping = (;color = :coefname));
    plot_parallelcoordinates(f[2,1],subset(results_plot,:channel=>x->x.<10); 
    mapping = (;color = :coefname),normalize=:minmax);
    f


```

## Labels
You can also provide labels for the axes

```@example main
plot_parallelcoordinates(subset(results_plot,:channel=>x->x.<5); 
    visual = (;color = :darkblue),ax_labels=["Fz","Cz","O1","O2"])

```

## tick-labels
There are three different options for the tick-labels

```@example main
f = Figure()
plot_parallelcoordinates(f[1,1],subset(results_plot,:channel=>x->x.<5); ax_ticklabels=:all,normalize=:minmax) # all tickets
plot_parallelcoordinates(f[2,1],subset(results_plot,:channel=>x->x.<5); ax_ticklabels=:left,normalize=:minmax) # extrema + tickets on the left
plot_parallelcoordinates(f[3,1],subset(results_plot,:channel=>x->x.<5); ax_ticklabels=:outmost,normalize=:minmax) # only show outmost

plot_parallelcoordinates(f[4,1],subset(results_plot,:channel=>x->x.<5); ax_ticklabels=:none,normalize=:minmax) #  show none
f
```


## Bending the parallel plot
it can be helpful to "bend" the lines

```@example main
f = Figure()
plot_parallelcoordinates(f[1,1],subset(results_plot,:channel=>x->x.<10))
plot_parallelcoordinates(f[2,1],subset(results_plot,:channel=>x->x.<10),bend=true)
f

```
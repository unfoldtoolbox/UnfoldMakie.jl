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

## Data generation
```@example main
include("../../example_data.jl")
r1, positions = example_data();
r2 = deepcopy(r1)
r2.coefname .= "B" # create a second category
r2.estimate .+= rand(length(r2.estimate))*0.1
results_plot = vcat(r1, r2);
nothing #hide
```

## Plot PCPs

```@example main
  plot_parallelcoordinates(
        subset(results_plot, :channel => x -> x .<= 5);
        mapping = (; color = :coefname),
    )
```


## Normalization
On the first image, there is no normalization and the extremes of all axes are the same and equal to the max and min values across all chanells. 
On the second image, there is a `minmax normalization``, so each axis has its own extremes based on the min and max of the data.

Typically, parallelplots are normalized per axis. Whether this makes sense for estimating channel x, we do not know.

```@example main
    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
    )
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .< 10);
        mapping = (; color = :coefname),
        normalize = :minmax,
    )
    f


```

## Labels
Use `ax_labels` to specify labels for the axes.

```@example main
    plot_parallelcoordinates(
        subset(results_plot, :channel => x -> x .< 5);
        visual = (; color = :darkblue),
        ax_labels = ["Fz", "Cz", "O1", "O2"],
    )

```

## Tick labels
Specify tick labels on axis. There are four different options for the tick labels.

```@example main
 f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_labels = ["Fz", "Cz", "O1", "O2"],
        ax_ticklabels = :all,
        normalize = :minmax,
    ) # all tick labels on all axis
    plot_parallelcoordinates(
        f[2, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_ticklabels = :left,
        normalize = :minmax,
    ) # tick labels on extremities + tickets on the left
    plot_parallelcoordinates(
        f[3, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_ticklabels = :outmost,
        normalize = :minmax,
    ) # show tick labels on extremities of axis

    plot_parallelcoordinates(
        f[4, 1],
        subset(results_plot, :channel => x -> x .< 5);
        ax_ticklabels = :none,
        normalize = :minmax,
    ) #  disable tick labels
    f 
```


## Bending the parallel plot
Bending the linescan be helpful to make them more visible.

```@example main
    f = Figure()
    plot_parallelcoordinates(f[1,1], 
        subset(results_plot, :channel=>x->x.<10))
    plot_parallelcoordinates(f[2,1], 
        subset(results_plot, :channel=>x->x.<10), bend=true)
    f

```

## Transparancy 
```@example main
    uf_5chan = example_data("UnfoldLinearModelMultiChannel")

    f = Figure()
    plot_parallelcoordinates(
        f[1, 1],
        uf_5chan;
        mapping = (; color = :coefname),
        layout = (; legend_position = :right),
        visual=(; alpha=0.1)
    )
    plot_parallelcoordinates(
        f[2, 1],
        uf_5chan;
        mapping = (; color = :coefname),
        layout = (; legend_position = :right),
        visual=(; alpha=0.9)
    )
    f

```

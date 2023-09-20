# [Include multiple Visualizations in one Figure](@id ht_mvf)

```@example main
using UnfoldMakie
using CairoMakie
using DataFramesMeta
using UnfoldSim
using Unfold
using MakieThemes
set_theme!(theme_ggthemr(:fresh)) # nicer defaults - should maybe be default?

```
```@example main
include("../../example_data.jl")
d_topo, positions = example_data("TopoPlots.jl")
uf_deconv = example_data("UnfoldLinearModelContinuousTime")
uf = example_data("UnfoldLinearModel")
results = coeftable(uf)
uf_5chan = example_data("UnfoldLinearModelMultiChannel")
d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched=true)
times = -0.099609375:0.001953125:1.0
nothing #hide
```
In this section we discuss how users are able to include multiple visualizations in a single figure.

By using the !-version of the plotting function and putting in a grid position instead of a full figure, we can create Multiple Coordinated Views.

You start by creating a figure with Makie.Figure. 

`f = Figure()`

Now each plot can be added to `f`  by putting in a grid position, such as `f[1,1]`.

```@example main

f = Figure()
plot_erp!(f[1, 1], coeftable(uf_deconv))
plot_erp!(f[1, 2], effects(Dict(:condition => ["car", "face"]), uf_deconv), mapping=(; color=:condition))
plot_butterfly!(f[2, 1:2], d_topo; positions=positions)

f
```

By using the data from the tutorials we can create a big image with every type of plot.

With so many plots at once it's incentivised to set a fixed resolution in your figure to order the plots evenly (Code below).


```@example main

f = Figure(resolution=(2000, 2000))

plot_butterfly!(f[1, 1:3], d_topo; positions=positions)

pvals = DataFrame(
    from=[0.1, 0.15],
    to=[0.2, 0.5],
    # if coefname not specified, line should be black
    coefname=["(Intercept)", "category: face"]
)
plot_erp!(f[2, 1:2], results, extra=(;
    categoricalColor=false,
    categoricalGroup=false,
    pvalue=pvals,
    stderror=true))


plot_designmatrix!(f[2, 3], designmatrix(uf))

plot_topoplot!(f[3, 1], collect(1:64); positions=positions, visual=(; colormap=:viridis))
plot_topoplotseries!(f[4, 1:3], d_topo, 0.1; positions=positions, mapping=(; label=:channel))

res_effects = effects(Dict(:continuous => -5:0.5:5), uf_deconv)

plot_erp!(f[2, 4:5], res_effects;
    mapping=(; y=:yhat, color=:continuous, group=:continuous),
    extra=(; showLegend=true,
        categoricalColor=false,
        categoricalGroup=true),
    legend=(; nbanks=2),
    layout=(; legendPosition=:right))

plot_parallelcoordinates!(f[3, 2:3], uf_5chan, [1, 2, 3, 4, 5]; mapping=(; color=:coefname), layout=(; legendPosition=:bottom))

plot_erpimage!(f[1, 4:5], times, d_singletrial)
plot_circulareegtopoplot!(f[3:4, 4:5], d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
    positions=positions, predictor=:time, extra=(; predictorBounds=[-0.3, 0.5]))

f
```


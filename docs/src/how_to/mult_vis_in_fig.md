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
data, positions = TopoPlots.example_data()
dat, evts = UnfoldSim.predef_eeg(; 
        onset=LogNormalOnset(μ=3.5, σ=0.4), 
        noiselevel=5
    )
dat_e, times = Unfold.epoch(dat, evts, [-0.1, 1], 100)
evts, dat_e = Unfold.dropMissingEpochs(evts, dat_e)
evts.Δlatency =  diff(vcat(evts.latency, 0)) *-1
dat_e = dat_e[1, :, :]
nothing #hide
```
This section discusses how users can incorporate multiple plots into a single figure.

By using the !-version of the plotting function and inserting a grid position instead of an entire figure, we can create multiple coordinated views.

We will start by creating a figure with Makie.Figure. 

`f = Figure()`

Now any plot can be added to `f` by placing a grid position, such as `f[1, 1]`.

```@example main

f = Figure()
plot_erp!(f[1, 1], coeftable(uf_deconv))
plot_erp!(f[1, 2], effects(Dict(:condition => ["car", "face"]), uf_deconv), 
    mapping=(; color=:condition))
plot_butterfly!(f[2, 1:2], d_topo; positions=positions)

f
```

Using the data from the tutorials, we can create a large image with any type of plot.

With so many plots at once, it's tempting to set a fixed resolution in your image to order the plots evenly (code below).

```@example main

f = Figure(resolution=(2000, 2000))

plot_butterfly!(f[1, 1:3], d_topo; positions=positions)

pvals = DataFrame(
    from=[0.1, 0.15],
    to=[0.2, 0.5],
    # if coefname not specified, line should be black
    coefname=["(Intercept)", "category: face"]
)
plot_erp!(f[2, 1:2], results, 
    categorical_color=false,
    categorical_group=false,
    pvalue=pvals,
    stderror=true)


plot_designmatrix!(f[2, 3], designmatrix(uf))

plot_topoplot!(f[3, 1], data[:, 150, 1]; positions=positions)
plot_topoplotseries!(f[4, 1:3], d_topo, 0.1; positions=positions, mapping=(; label=:channel))

res_effects = effects(Dict(:continuous => -5:0.5:5), uf_deconv)

plot_erp!(f[2, 4:5], res_effects; categorical_color=false, categorical_group=true,
    mapping=(; y=:yhat, color=:continuous, group=:continuous),
    legend=(; nbanks=2),
    layout=(; show_legend=true, legend_position=:right))

plot_parallelcoordinates!(f[3, 2:3], uf_5chan, [1, 2, 3, 4, 5]; mapping=(; color=:coefname), 
    layout=(; legend_position=:bottom))

plot_erpimage!(f[1, 4:5], times, dat_e; sortvalues=evts.Δlatency)
plot_circulareegtopoplot!(f[3:4, 4:5], d_topo[in.(d_topo.time, Ref(-0.3:0.1:0.5)), :];
    positions=positions, predictor=:time, predictor_bounds=[-0.3, 0.5])

f
```


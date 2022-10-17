# [Generate a Timeexpanded Designmatrix](@id ht_gen_te_designmatrix)

In the following we discuss how to generate a Timeexpanded Designmatrix.

You start by repeating the first steps (up to and including the Data segment) of the [Designmatrix Visualization tutorial](@ref dm_vis).
Afterwards you continue as follows.

## Plot Timeexpanded Designmatrix

In the code below, data of the `Unfold` module was used.
To display a timeexpanded designmatrix we add the following code:
```@example main
using Unfold
using UnfoldMakie

include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data

data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA

bfDict = Dict(Any=>(f,basisfunction))
ufCont = UnfoldLinearModelContinuousTime(bfDict)

designmatrix!(ufCont, evts)
```

This is how you plot the timeexpanded designmatrix.
```@example main
plot_designmatrix(designmatrix(ufCont))
```


We set `sortData=false`, as it makes no sense to sort data for timeexpanded designmatrices (and it is `true` by default).
```@example main
plot_designmatrix(designmatrix(ufCont);setExtraValues=(sortData=false,))
```

Note that without further adjustments in the configuration, you may experience cluttering of labels. 
As you can see, this is the case here. 

In order to avoid the cluttering problem, we can limit the number of labels by changing the `xTicks`.
```
plot_designmatrix(designmatrix!(ufCont,evts);setExtraValues=(sortData=false,xTicks=12,))
```
In this case it was set to 12 labels on the x-axis.


As you can see labels are cut off to the left.
In the [corresponding How To section](@ref ht_soobl) you can see a workaroundfor it.
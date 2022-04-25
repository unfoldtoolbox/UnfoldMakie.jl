## Setup
```@example main
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie


include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data
data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA


ufMass = UnfoldLinearModel(Dict(Any=>(f,-0.4:1/50:.8)))
designmatrix!(ufMass, evts)
```

## Plot Designmatrix
```@example main
plot(designmatrix(ufMass))
```

Often it is helpful to sort the designmatrix

```@example main
plot(designmatrix(ufMass),sort=true)
```

You can also turn columnwise standardization off
```@example main
plot(designmatrix(ufMass),standardize=false)
```


## Plot Timeexpanded Designmatric
To see the result of the timeexpanded designmatrix, we can simply call plot on an Timeexpanded UnfoldObject
```@example main
bfDict = Dict(Any=>(f,basisfunction))
ufCont = UnfoldLinearModelContinuousTime(bfDict)
designmatrix!(ufCont, evts) # add the designmatrix but don't fit

plot(designmatrix(ufCont))
```

Currently there is no easy way to get the non-timeexpanded designmatrix from a `UnfoldLinearModelContinuousTime`

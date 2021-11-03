## Setup
```@example
using Unfold
using UnfoldMakie
using StatsModels
using DataFrames
using CairoMakie


include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities") ) # to load data
data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA


ufMass = UnfoldLinearModel(Dict(Any=>(f,-0.4:1/50:.8)))
designmatrix!(ufMass, evts)
```

### Default Plot
```@example
plot(designmatrix(ufMass))
```

Often it is helpful to sort the designmatrix

```@example
plot(designmatrix(ufMass),sort=true)
```

You can also turn columnwise standardization off
```@example
plot(designmatrix(ufMass),standardize=false)
```


### Timeexpanded plot
To see the result of the timeexpanded designmatrix, we can simply call plot on an Timeexpanded UnfoldObject
```@example
bfDict = Dict(Any=>(f,basisfunction))
ufCont = UnfoldLinearModelContinuousTime(bfDict)
designmatrix!(ufCont, evts)

plot(designmatrix(ufCont))
```

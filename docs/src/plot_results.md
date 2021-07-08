## Setup
```@example
using Unfold
using UnfoldMakie
using StatsModels
using MixedModels

include(joinpath(dirname(pathof(MyModule)), "test/test_utilities") ) # to load data
dat, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+conditionB
bfDict = Dict(Any=>(f,basisfunction))

m,results = fit(UnfoldLinearModel,bfDict,evts,data); 
```

### Default Plot
```@example
plot_results(results)
```

### With StandardErrors
```@example
m,results = Unfold.fit(UnfoldLinearModel,bfDict,evts,data,solver=se_solver)
plot_results(results,stderror=true)
```

### Two different events
```@example

dat, evts = loadtestdata("test_case_4b");
bf1 = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulusA")
bf2 = firbasis(τ=(-0.2,1.2),sfreq=50,name="stimulusB")

f  = @formula 0~1
bfDict = Dict(:EventA=>(f,bf1),
              :EventB=>(f,bf2))

m,results = Unfold.fit(UnfoldLinearModel,bfDict,evts,data,solver=se_solver)

plot_results(results,stderror=true)
```
## Setup
```@example
using Unfold
using UnfoldMakie
using StatsModels
using MixedModels
using DataFrames
using CairoMakie


include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities") ) # to load data
data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA

bfDict = Dict(Any=>(f,basisfunction))

m = fit(UnfoldModel,bfDict,evts,data); 
results = coeftable(m)
```

### Default Plot
```@example
plot_results(results)
```

### With StandardErrors
```@example
se_solver = solver=(x,y)->Unfold.solver_default(x,y,stderror=true)
m = Unfold.fit(UnfoldModel,bfDict,evts,data.+10 .*rand(length(data)),solver=se_solver)

results = coeftable(m)
plot_results(results,stderror=true)
```

### Two different events
```@example

data, evts = loadtestdata("test_case_4b");
bf1 = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulusA")
bf2 = firbasis(τ=(-0.2,1.2),sfreq=50,name="stimulusB")

f  = @formula 0~1
bfDict = Dict("eventA"=>(f,bf1),
              "eventB"=>(f,bf2))

results = coeftable(fit(UnfoldModel,bfDict,evts,data,solver=se_solver,eventcolumn="type"))

plot_results(results,stderror=true)
```
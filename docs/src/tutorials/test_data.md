## [Load Data](@id test_data)

In case you do not have data to visualize line plots, you can follow along this step to get data. You can also use this as a reference on how to load your own data. 
With the exception of example data for topo plots which can be found in [General Topo Plot Visualization](@ref tp_vis), information on how to load example data for other types of visualizations are detailed here.

## Test Data from the Unfold Module
The `Unfold` module offers some test data (useful e. g. for designmatrix visualization). 
In the following we load the data. 
```
include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data

data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA

ufMass = UnfoldLinearModel(Dict(Any=>(f,-0.4:1/50:.8)))
```
Here we used the FIR basisfunction.
For more information on basisfunctions see the [Unfold.jl documentation](https://unfoldtoolbox.github.io/Unfold.jl/dev/explanations/basisfunctions/).

### Properties of resulting used variables:

- `data`:	is of type `Vector{Float64} (alias for Array{Float64, 1})` with a size of `(12000,)`
- `evts`:	is of type `DataFrame` with size of `(397, 5)` and the columns:
	- `latency`:	is of type `Int64`
	- `type`:	is of type `String7`
	- `intercept`:	is of type `Int64`
	- `conditionA`:	is of type `Int64`
	- `continuousA`:	is of type `Float64`
- `ufMass`:	is of type `UnfoldLinearModel` (more information at the [Unfold module](https://github.com/unfoldtoolbox/Unfold.jl))


## Test Data erpcore-N170.jld2
Download the `erpcore-N170.jld2` data file from [figshare](https://figshare.com/articles/dataset/erpcore-N170_jld2/19762705). 

As we manually load data we use the following modules:
```
using FileIO
using JLD2
```
Now you can load the data as follows:
```
p_all = "erpcore-N170.jld2"
presaved_data = load(p_all)
dat_e = presaved_data["data_e_all"].* 1e6
evt_e = presaved_data["df_e_all"]
```
Note that if you have not placed the file in the same directory as your project, you need to specify the directory in the `p_all` variable.
Use slash `/` for the folder path. 

As UnfoldMakie uses data of a type in line with the Unfold module, we have to process the data now such that it can be used:
```
# times vector (from-to)
times = range(-0.3, length=size(dat_e,2), step=1 ./ 128)

# get standard errors
se_solver =(x,y)->Unfold.solver_default(x,y,stderror=true)
# define effect-coding
contrasts= Dict(:category => EffectsCoding(), :condition => EffectsCoding())
	
analysis_formula = @formula 0 ~ 1 + category * condition
	
results_allSubjects = DataFrame()
	
for sub ∈ unique(evt_e.subject)

	# select events of one subject
    sIx = evt_e.subject .== sub

	# fit Unfold-Model
	# declaring global so we can access the variable outside of this loop (local vs. global scope)
    global mres = Unfold.fit(UnfoldModel, 
					analysis_formula, 
					evt_e[sIx,:], 
					dat_e[:,:,sIx], 
					times, 
					contrasts=contrasts,
					solver=se_solver);

	# make results of one subject available
	global results_onesubject = coeftable(mres)

	# concatenate results of all subjects
    results_onesubject[!,:subject] .= sub
    append!(results_allSubjects,results_onesubject)
end
```


### Properties of resulting used variables:

- `results_onesubject`:	is of type `DataFrame` with a size of `(25476, 8)` and columns:
	- `basisname`:	is of type `String`
	- `channel`:	is of type `Int64`
	- `coefname`:	is of type `String`
	- `estimate`:	is of type `Float64`
	- `group`:	is of type `Nothing`
	- `stderror`:	is of type `Float64`
	- `time`:	is of type `Float64`
	- `subject`:	is of type `Int64`
- `mres`:	is of type `UnfoldLinearModel` (more information at the [Unfold module](https://github.com/unfoldtoolbox/Unfold.jl))


## TODO: is data really used?
## [Load Data](@id test_data)

In case you do not have data to visualize line plots, you can follow along this step to get data.

### Test Data from the Unfold Module
The `Unfold` module offers some test data (useful e. g. for designmatrix visualization). 
In the following we load the data. 
```@example main
include(joinpath(dirname(pathof(Unfold)), "../test/test_utilities.jl") ) # to load data

data, evts = loadtestdata("test_case_3b");
basisfunction = firbasis(τ=(-0.4,.8),sfreq=50,name="stimulus")
f  = @formula 0~1+conditionA+continuousA
```
Here we used the FIR basisfunction.
For more information on basisfunctions see the [Unfold.jl documentation](https://unfoldtoolbox.github.io/Unfold.jl/dev/explanations/basisfunctions/).

### Test Data erpcore-N170.jld2
[](https://figshare.com/articles/dataset/N170_Single_Subject_ERPCore/19762960)
Download the `erpcore-N170.jld2` file from this [website](https://figshare.com/articles/dataset/erpcore-N170_jld2/19762705). 

As we manually load data we use the following modules:
```@example main
using FileIO
using JLD2
```
Now you can load the data as follows:
```@example main
p_all = "erpcore-N170.jld2"
presaved_data = load(p_all)
dat_e = presaved_data["data_e_all"].* 1e6
evt_e = presaved_data["df_e_all"]
```
Note that if you have not placed the file in the same directory as your project, you need to specify the directory in the `p_all` variable.
Use slash `/` for the folder path. 

As the data is quite expansive, we do some pre-processing in order to be able to more easily use it:
```@example main
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

## TODO MORE TEST DATA?
[sub-002_ses-N170_task-N170_eeg.set](https://figshare.com/articles/dataset/N170_Single_Subject_ERPCore/19762960)
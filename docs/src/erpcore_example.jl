### A Pluto.jl notebook ###
# v0.19.4

using Markdown
using InteractiveUtils

# ╔═╡ 4c7907ad-bc25-4188-ade7-fa69e6fc719d
# ╠═╡ show_logs = false
begin
		using Pkg # cant use internal package manager because we need the topoplot version of UnfoldMakie
		Pkg.activate(temp=true)
	
end

# ╔═╡ 29fca132-7f60-4caa-805f-155babb6832d
# ╠═╡ show_logs = false
# install packages
begin
Pkg.add.(["DataFramesMeta","JLD2","StatsModels","Unfold","PyMNE","CairoMakie", "CSV","DataFrames","StatsBase","FileIO","AlgebraOfGraphics","MixedModels","CategoricalArrays"])

	
	
end;

# ╔═╡ ec872fd2-6a92-46b5-bc6e-87ba28db1b09
# ╠═╡ show_logs = false
Pkg.add(url="https://github.com/unfoldtoolbox/UnfoldMakie.jl",rev="topoplot")

# ╔═╡ d609f3e3-ff6a-4a96-a359-e44dba93c0e0
using UnfoldMakie

# ╔═╡ f3f93d30-d2b6-11ec-3ba2-898080a75c3f
begin
	using Unfold
	using PyMNE # MNE is a python library for EEG data analysis
	using AlgebraOfGraphics # plotting Grammar of Graphics
	using CSV
	using DataFrames
	using  StatsBase # mean/std
	using FileIO # loading data
	using JLD2 # loading data
	using StatsModels # UnfoldFit
	using CairoMakie # Plotting Backend (SVGs/PNGs)
	using Printf # interpolate strings
	
	using DataFramesMeta # @subset etc. working with DataFrames
end

# ╔═╡ d6119836-fc49-4731-82a6-66d25963ba2c
begin # load  one single-subject dataset
	
	# once artifacts are working, we could ship it. But for now you have to download it and 
 #p =joinpath(pathof(UnfoldMakie),"artifacts","sub002_ses-N170_task-N170_eeg.set")
	    
	p = "/store/users/ehinger/projects/unfoldjl_dev/dev/UnfoldMakie/artifact/sub-002_ses-N170_task-N170_eeg.set"
    raw = PyMNE.io.read_raw_eeglab(p,preload=false)
end;

# ╔═╡ c6bb6bbb-55a4-4bfd-bb12-24307607248a
begin # load unfold-fitted dataset of all subjects
	# takes ~25s to load because it is quite large :)
	p_all = "/store/users/ehinger/projects/unfoldjl_dev/data/erpcore-N170.jld2"
	presaved_data = load(p_all)
	dat_e = presaved_data["data_e_all"].* 1e6
	evt_e = presaved_data["df_e_all"]
end;

# ╔═╡ 434a957c-ec3f-4496-a7e6-a0ec4b431754
# ╠═╡ show_logs = false
begin
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
	
end

# ╔═╡ 9c17bcfb-9106-4b67-948c-94aa31662418
   let # We are fitting only one channel!
	   
	   using MixedModels, CategoricalArrays
	   	lmm_formula = @formula 0 ~ 1 + category + zerocorr(1+category|subject)
	evt_lmm = deepcopy(evt_e)
	@transform!(evt_lmm,:subject=categorical(:subject))

   lmm = Unfold.fit(UnfoldModel, 
						lmm_formula, 
	   					evt_lmm,
						dat_e[1:1,:,:], 
						times, 
						contrasts=contrasts);
	   plot_results(coeftable(lmm))
   end

# ╔═╡ 343f3c15-7f48-4e25-84d5-f4ef01d35db7
md"""## Designmatrix"""

# ╔═╡ 7cbe5fcb-4440-4a96-beca-733ddcb07861
plot(designmatrix(mres),sort=true)

# ╔═╡ d329586a-fd05-4729-a0c3-4700ee22a498
md"""## Butterfly-plot?"""

# ╔═╡ 975382de-5f24-4e9e-87f6-a7f7ba93ff8e
let # let (against begin) makes a local environment, not sharing the modifications / results wiht outside scripts. Beware of field assignments x.blub = "1,2,3" will overwrite x.blub, x = [1,2,3] will not overwrite global x, but make a copy
	
results_plot = @subset(results_onesubject,:coefname .== "(Intercept)",:channel .<5)
plot_results(results_plot,color=:channel,layout=:channel)
end

# ╔═╡ 3ba4d6bc-ffaa-456e-8d85-334d60ebbd77
let
results_plot = @subset(results_allSubjects,:coefname .== "(Intercept)",:channel .==1)
plot_results(results_plot,color=:subject)
end

# ╔═╡ 62632f86-5792-49c3-a229-376211deae64
md"""
## Lineplot
ManyFactors
"""

# ╔═╡ 41e1b735-4c19-4e6d-8681-ef0f893aec87
let # let (against begin) makes a local environment, not sharing the modifications / results wiht outside scripts. Beware of field assignments x.blub = "1,2,3" will overwrite x.blub, x = [1,2,3] will not overwrite global x, but make a copy
	
results_plot = @subset(results_onesubject,:channel .==22)
plot_results(results_plot,stderror=true)
end

# ╔═╡ a92e775f-eede-4a0f-a404-8ed61abe6804
md"## P-value significance"

# ╔═╡ 5840f82c-8e0f-4bbe-8e83-6e79eae11823
pathof(UnfoldMakie)

# ╔═╡ c0e53025-7f23-4520-b22c-d271b8c528a9
let 
pvals = DataFrame(
			from=[0.1,0.3],
			to=[0.5,0.7],
			coefname=["(Intercept)","category: face"] # if coefname not specified, line should be black
		) 
	

	#pvals = DataFrame(from=[0.1],to=[0.5])
results_plot = @subset(results_onesubject,:channel .==22)
plot_results(results_plot,pvalue=pvals)
end

# ╔═╡ cb396666-93d7-41e3-b958-55df52fc516e
md"""## Linear Mixed Models
The "rows" is one potential way to display multiple groups ala fixef / ranef.

See the next example for multiple events as well
"""

# ╔═╡ 35094a17-2be0-4d57-8846-3ed31a04e689
md"""
## Multiple basisfunctions
It is possible to have multiple events to cut your data to

As this is not 100% implemented for mass-univariate non-deconvolution models (i.e. you could concatenate different LMMs) I refer to this tutorial https://unfoldtoolbox.github.io/UnfoldMakie.jl/dev/plot_results/

But just to show what I mean, let's do a trickery doo
"""

# ╔═╡ 3c607414-0760-48ab-961c-ab74d6df6522
let
	r1 = @subset(results_onesubject,:channel .==22)
	r2 = @subset(results_onesubject,:channel .==25)
	r1.basisname .= "eventA"
	r2.basisname .= "eventB"
	results_plot = vcat(r1,r2)
	plot_results(results_plot)
end

# ╔═╡ 98026af7-d875-43f3-a3cb-3109faef5822
md"""
## Topoplots
"""

# ╔═╡ 3cee30ae-cf25-4684-bd49-c64b0b96b4e6
begin
	mon = PyMNE.channels.make_standard_montage("standard_1020")
	raw.set_channel_types(Dict("HEOG_left"=>"eog","HEOG_right"=>"eog","VEOG_lower"=>"eog"))
	raw.set_montage(mon,match_case=false)
	
	pos = PyMNE.channels.make_eeg_layout(get_info(raw)).pos
end;

# ╔═╡ 5f0f2708-f2d9-4a72-a528-185837a43e06
# potentially still buggy: The sensor-positions are flipped 90°
plot_topoplot_series(@subset(results_onesubject,:coefname.=="(Intercept)",:channel .<=30),0.2,topoplotCfg=(positions=collect(pos[:,[2,1]]),))


# ╔═╡ 6ee180df-4340-45a2-bb1e-37aad7953875
# maybe this should be the default
# note the bad time on top :S
plot_topoplot_series(@subset(results_onesubject,:coefname.=="(Intercept)",:channel .<=30),0.2,topoplotCfg=(sensors=false,positions=collect(pos[:,[2,1]]),),mappingCfg=(col=:time,))

# ╔═╡ f0f752d8-7f2d-4a49-8763-53df2cff6126
# multi-coeffiecients dont work, because the aggregation is on groupby (channel)
plot_topoplot_series(@subset(results_onesubject,:channel .<=30),0.2,topoplotCfg=(sensors=false,positions=collect(pos[:,[2,1]]),),mappingCfg=(col=:time,row=:coefficient))

# ╔═╡ 7da4df51-589a-4eb5-8f1f-f77ab65cf10a
@subset(results_onesubject,:coefname.=="(Intercept)")

# ╔═╡ Cell order:
# ╠═4c7907ad-bc25-4188-ade7-fa69e6fc719d
# ╠═29fca132-7f60-4caa-805f-155babb6832d
# ╠═d609f3e3-ff6a-4a96-a359-e44dba93c0e0
# ╠═ec872fd2-6a92-46b5-bc6e-87ba28db1b09
# ╠═f3f93d30-d2b6-11ec-3ba2-898080a75c3f
# ╠═d6119836-fc49-4731-82a6-66d25963ba2c
# ╠═c6bb6bbb-55a4-4bfd-bb12-24307607248a
# ╠═434a957c-ec3f-4496-a7e6-a0ec4b431754
# ╠═343f3c15-7f48-4e25-84d5-f4ef01d35db7
# ╠═7cbe5fcb-4440-4a96-beca-733ddcb07861
# ╟─d329586a-fd05-4729-a0c3-4700ee22a498
# ╠═975382de-5f24-4e9e-87f6-a7f7ba93ff8e
# ╠═3ba4d6bc-ffaa-456e-8d85-334d60ebbd77
# ╟─62632f86-5792-49c3-a229-376211deae64
# ╠═41e1b735-4c19-4e6d-8681-ef0f893aec87
# ╠═a92e775f-eede-4a0f-a404-8ed61abe6804
# ╠═5840f82c-8e0f-4bbe-8e83-6e79eae11823
# ╠═c0e53025-7f23-4520-b22c-d271b8c528a9
# ╠═cb396666-93d7-41e3-b958-55df52fc516e
# ╠═9c17bcfb-9106-4b67-948c-94aa31662418
# ╟─35094a17-2be0-4d57-8846-3ed31a04e689
# ╠═3c607414-0760-48ab-961c-ab74d6df6522
# ╠═98026af7-d875-43f3-a3cb-3109faef5822
# ╠═3cee30ae-cf25-4684-bd49-c64b0b96b4e6
# ╠═5f0f2708-f2d9-4a72-a528-185837a43e06
# ╠═6ee180df-4340-45a2-bb1e-37aad7953875
# ╠═f0f752d8-7f2d-4a49-8763-53df2cff6126
# ╠═7da4df51-589a-4eb5-8f1f-f77ab65cf10a

### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 80e36c32-187f-41ba-82eb-d84c22de6d69
using Pkg


# ╔═╡ 7b3eca23-cc2a-4212-abc3-70f941afb4d4
begin
Pkg.activate(mktempdir())
	Pkg.add(name="micromamba_jll",version="1.3")
	Pkg.add(["UnfoldMakie","PyMNE","CairoMakie","Unfold","CSV","DataFrames","CoordinateTransformations","PlutoUI","StaticArrays","Statistics"])
end


# ╔═╡ ea3e73be-2bb6-11ee-0b04-43b39a893537
begin
using UnfoldMakie
	using PyMNE
	using CairoMakie
	using Unfold
	using CSV
	using DataFrames
	using CoordinateTransformations
	using PlutoUI
	using StaticArrays
	using Statistics
	import StatsBase.mean
end

# ╔═╡ e0c29a25-1ccd-455b-b99b-fa93c72310d4
using TopoPlots

# ╔═╡ 5451c8fd-c1cf-4088-9e0b-6fed0c388bf7
TableOfContents()

# ╔═╡ 256e9785-9f54-4546-ac51-53c2a22e6c79
md"""
### Load Data
"""

# ╔═╡ ba178d91-1d03-40f1-97ea-ec03b8bd29c6


# ╔═╡ c0f10639-eda1-4af5-b877-00406b066de0
begin
evts = CSV.read("/store/data/WLFO/derivatives/preproc_agert/sub-20/eeg/sub-20_task-WLFO_events.tsv",DataFrame)
	evts.latency = evts.onset .* 512
end

# ╔═╡ a8cf7a53-6d5e-4400-a3bd-80034a7ed5f6
evts_fix = subset(evts,:type => x->x.=="fixation")

# ╔═╡ 15533746-a53e-4694-b8ca-285bc20f83c5
raw = PyMNE.io.read_raw_eeglab("/store/data/WLFO/derivatives/preproc_agert/sub-20/eeg/sub-20_task-WLFO_eeg.set")

# ╔═╡ 67470dc9-3282-4462-a675-b00d8a9c9241
begin
pos3= pyconvert(Array,raw._get_channel_positions());
	pos3[:,2] = -pos3[:,2]
	pos3[:,1] = -pos3[:,1]
end

# ╔═╡ b2efb84a-1f96-4671-b25e-65001cba12a2
d,times = Unfold.epoch(pyconvert(Array,raw.get_data(units="uV")),evts_fix,(-0.1,1),512)

# ╔═╡ df5ff6e9-505f-4a25-97aa-e19be6286c8f
md"""
## Synched ChannelImage
"""

# ╔═╡ 1b025463-936f-432c-91a1-056d0d9b9bcd


# ╔═╡ 3f0fa6da-3790-4264-beba-4785eb1bb0ee
begin
    function chanselectTopoplot(pos::Vector;labels=nothing,label_text=false,markersize=21,obs=nothing)
		
    labels = isnothing(labels) ? (1:length(pos)) : labels
		
    f,topoaxis,h = eeg_topoplot(zeros(length(pos)), labels;
        positions=pos, 
        interpolation=NullInterpolator(),
        enlarge=1,
        label_text,
        label_scatter=(markersize=markersize, color=:black)
    ) 
    hidedecorations!(current_axis())
    hidespines!(current_axis())

    obs = isa(obs,Observable) ? obs : Observable(1)
    str = lift((obs, labels) -> "$(labels[obs])", obs, labels)
    text!(topo_axis, 1, 1, text = str,  align = (:center, :center))
    on(events(f).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            plt, p = pick(topo_axis)
            obs[] = p
        end
    end
    f
		return obs,f
	end
end

# ╔═╡ 933f3050-4c0e-44b3-89e7-4dc59591128d
@bind chanOrder PlutoUI.Select(["chanorder","cluster","X","Y","Z"])

# ╔═╡ 93dc3a57-6b20-4fe8-abf8-b54ef7a8ab7e
@bind sorttime PlutoUI.Slider(0:500)

# ╔═╡ 5c14e245-6b95-4c4d-85f6-bfbff95ca013
	let
	d_m = mean(d,dims=3)[:,:,1]
	series(d_m,solid_color=:black)
	end

# ╔═╡ d4c2e872-2bad-44ce-8a9a-42b549464678


# ╔═╡ 8c70f1c1-313c-4b3b-b4e7-c14818ec9f57
md"""
# ERPImage
"""

# ╔═╡ 6d9c9e59-242e-4021-a972-db57b1b4f58b
heatmap(d[1,:,:]) # channel x time x trials

# ╔═╡ 23f118e1-ceed-407f-9063-f0c49138077b
@bind sortby PlutoUI.Select(names(evts_fix))

# ╔═╡ 16369ac8-6cd4-481c-b2dc-b2d884afbfe1
evts_fix

# ╔═╡ cb8b03b7-6457-4fa1-ab4a-84bd1faffbf4
coalesce.(d[1,:,:],NaN)

# ╔═╡ d42c85dd-ecb7-4e97-87fa-7dbd1746102c
begin

	# no times + no figure?
plot_erpimage2(plotData::Matrix{<:Real}; kwargs...) = plot_erpimage2!(Figure(),plotData; kwargs...)

	# no times?
plot_erpimage2!(f::Figure,plotData::Matrix{<:Real}; kwargs...) = plot_erpimage2!(f, 1:size(plotData,1), plotData; kwargs...)

	# no figure?
plot_erpimage2(times::AbstractVector,plotData::Matrix{<:Real}; kwargs...) = plot_erpimage2!(Figure(),times, plotData; kwargs...)
	
function plot_erpimage2!(f::Union{GridPosition,Figure}, times::AbstractVector,plotData::Matrix{<:Real}; sortvalues = nothing,sortix=nothing,kwargs...)
    config = PlotConfig(:erpimage)
    UnfoldMakie.config_kwargs!(config; kwargs...)

	
	!isnothing(sortix) ? @assert(sortix isa Vector{Int}) : ""
    ax = Axis(f[1:4, 1]; config.axis...)
	if isnothing(sortix)
		if isnothing(sortvalues)
			sortix = 1:size(plotData,2)
		else
			sortix = sortperm(sortvalues)

		end
	end

    filtered_data = UnfoldMakie.imfilter(plotData[:, sortix], UnfoldMakie.Kernel.gaussian((0, max(config.extra.erpBlur, 0))))

	
    #if config.extra.sortix
     #   ix = sortperm([a[1] for a in argmax(plotData, dims=1)][1, :])   # ix - trials sorted by time of maximum spike
	
	yvals = 1:size(filtered_data,2)
    if !isnothing(sortvalues)
		yvals = [minimum(sortvalues),maximum(sortvalues)]
	end
	
	hm = heatmap!(ax,times,yvals, filtered_data; config.visual...)

    UnfoldMakie.applyLayoutSettings!(config; fig=f, hm=hm, ax=ax, plotArea=(4, 1))

    if config.extra.meanPlot
        # UserInput
        subConfig = deepcopy(config)
        config_kwargs!(subConfig; layout=(;
                showLegend=false
            ),
            axis=(;
                ylabel=config.colorbar.label === nothing ? "" : config.colorbar.label))


        #limits = (config.axis.limits[1], config.axis.limits[2], nothing, nothing)))

        axisOffset = (config.layout.showLegend && config.layout.legendPosition == :bottom) ? 1 : 0
        subAxis = Axis(f[5+axisOffset, 1]; subConfig.axis...)

        lines!(subAxis, mean(plotData, dims=2)[:, 1])
        applyLayoutSettings!(subConfig; fig=f, ax=subAxis)
    end

    return f

end
end

# ╔═╡ eb3ed1d4-6ad7-4807-8a7a-10313b11b067
let
f = Figure()
d_nan = coalesce.(d[100,:,:],NaN)
	d_nan = d_nan .- mean(d_nan,dims=2)[:,1]
	#d_nan = d_nan .+ mean(d_nan,dims=1)[:,1]
v = (;colorrange = (-10,10))
	e = (;erpBlur = 5)
@show size(d_nan)
plot_erpimage2!(f[1,1],times,d_nan,visual=v,extra=e)
plot_erpimage2!(f[1,2],times,d_nan;extra=e,sortvalues = diff(evts_fix.onset./100),visual=v)
plot_erpimage2!(f[2,1],times,d_nan;extra=e,sortvalues = evts_fix.sac_startpos_x,visual=v)
plot_erpimage2!(f[2,2],times,d_nan;extra=e,sortvalues=evts_fix.sac_amplitude,visual=v)
f
end

# ╔═╡ 6539620f-7d85-40c4-b5f1-dda42bc9e3e9
begin
d_nan = coalesce.(d[1,:,:],NaN)

	plot_erpimage2(times,d_nan,;sortvalues=evts_fix[:,sortby],extra=(;erpBlur=50))

end

# ╔═╡ 5548c28e-f67f-4873-9f90-d91ba0aaa42b
md"""
## 3D to 2D
"""

# ╔═╡ 776e0206-91ee-4800-83ec-8b6bdb06505a

	function cart3d_to_spherical(x,y,z)
		sph = SphericalFromCartesian().(SVector.(x,y,z))
		sph = [vcat(s.r,s.θ,π/2 - s.ϕ) for s in sph] 
		sph = hcat(sph...)'
		return sph
	end


# ╔═╡ 03462e09-692b-47e0-96c0-bc730fcaf200
pos3D_to_layout(pos3::AbstractMatrix;kwargs...) =pos3D_to_layout(pos3[:,1],pos3[:,2],pos3[:,3];kwargs...)

# ╔═╡ 8513fc7f-cd5a-4ea3-b131-c1bcbcfb4878
function pos3D_to_layout(x,y,z;sphere=[0,0,0.])
	#cart3d_to_spherical(x,y,z)
	
# translate to sphere origin
	x .-= sphere[1]
	y .-= sphere[2]
	z .-= sphere[3]
	
	# convert to spherical coordinates
	sph = cart3d_to_spherical(x,y,z)

	# get rid of of the radius for now
	pol_a = sph[:,3]
	pol_b = sph[:,2]
	
	# use only theta & phi, convert back to cartesian coordinates
	p_x = pol_a .* cos.(pol_b)
	p_y = pol_a .* sin.(pol_b)

	# scale by the radius
	p_x .*= sph[:,1] ./(π/2)
	p_y .*= sph[:,1] ./(π/2)

	# move back by the sphere coordinates
	p_x .+= sphere[1]
	p_y .+= sphere[2]

	diff(m::Tuple) = [m[1],m[2]]
	p_x .= p_x ./ (2* diff(extrema(p_x))[1])
	p_y .= p_y ./ (2* diff(extrema(p_y))[1])

	p_x = p_x .+ 0.5
	p_y = p_y .+ 0.5
  return Point2f.(p_x,p_y)
end

# ╔═╡ 461827a5-8597-4a05-9201-4cf94af01b58
begin
pos2 = pos3D_to_layout(pos3)

end

# ╔═╡ 01c13032-2b18-4cc3-8e62-975448e390a1
extrema([p[1] for p in pos2])

# ╔═╡ ca9835eb-0a68-461e-884f-9ca75a584d92
begin
obs,f = chanselectTopoplot(pos2)
	f
end

# ╔═╡ 85de4fff-8eb3-4193-b11d-a545d4f60a05
begin
	global obs_pluto
on(obs) do val
	global obs_pluto = val
end
end

# ╔═╡ a91e1f64-fd06-4648-9352-4533eff5aaaa
obs_pluto

# ╔═╡ ec1915aa-8c07-400c-ad09-2637a74aceee
begin

f2 = Figure(resolution=(1000,500))
	d_m = mean(d,dims=3)[:,:,1]
	d_m = disallowmissing(d_m)

	if chanOrder == "chanorder"
		
	sortix =(1:length(pos2))
	elseif chanOrder == "cluster"
		sortix = sortperm(d_m[:,sorttime])
	elseif chanOrder == "X"
		sortix = sortperm(pos3[:,1])
	elseif chanOrder == "Y"
sortix = sortperm(pos3[:,2])
	elseif chanOrder =="Z"
		sortix = sortperm(pos3[:,3])
	end
	
	axzoom = (;limits=((-0.25, 1.25), (-0.25, 1.25)))
	
	ax,h = heatmap(f2[1,2:7],d_m[sortix,:]',colormap=Reverse("RdBu"),colorrange = [-15,15])
	Colorbar(f2[1,8],h)
	vlines!(current_axis(),[sorttime])
d_tmp = UnfoldMakie.eeg_matrix_to_dataframe(d_m,string.(1:size(d_m,1)))
	d_tmp.channel = parse.(Int,d_tmp.label)
	
	
h = plot_topoplotseries!(f2[2,2:7],d_tmp,75;positions=pos2,visual=(;interp_resolution=(128,128),enlarge=1,label_scatter=false,contours=false),labels=nothing)

	hLeg = plot_topoplot!(f2[2,1],Float32.(1:length(pos2));positions=pos2,visual=(;interpolation=TopoPlots.NullInterpolator(),enlarge=0.9),layout=(;showLegend=false),axis=(;aspect=1,axzoom...))
	
#	colgap!(h.layout.content[2].content,0)
	#rowgap!(h.layout.content[2].content,1100)
rowsize!(f2.layout, 2, Relative(1/4))

f2
end

# ╔═╡ 23dca8b4-9166-41fc-bf42-9d6d57f29da6
begin
f3 = Figure()
#GridLayout(f3[1,1])
for (ix,chO) = enumerate(["chanorder","cluster","X","Y","Z"])
	if chO == "chanorder"
		
	sortix =(1:length(pos2))
	elseif chO == "cluster"
		sortix = sortperm(d_m[:,100])
	elseif chO == "X"
		sortix = sortperm(pos3[:,1])
	elseif chO == "Y"
sortix = sortperm(pos3[:,2])
	elseif chO =="Z"
		sortix = sortperm(pos3[:,3])
	end
	@show mod(ix-1,2)
	@show ix
	
	heatmap(f3[mod(ix-1,2)+1,ix÷2],d_m[sortix,:]',axis=(;title=chO))
end
	f3
	
end

# ╔═╡ 6f3fb600-013c-4b18-92e8-fe6c0990f0a1
plot_topoplotseries!(Figure(),d_tmp,100;positions=pos2,visual=(;interp_resolution=(128,128),enlarge=1))
	

# ╔═╡ 95426b22-deb7-4b58-bb43-67c368cb9ab9
let
f = Figure()
plot_topoplot!(f[1,1],Float32.(1:length(pos2));positions=pos2,visual=(;interpolation=TopoPlots.NullInterpolator(),enlarge=0.9,markersize=20),layout=(;showLegend=false))
	plot_topoplot!(f[1,2],Float32.(zeros(length(pos2)).+0.1*rand(length(pos2)));positions=pos2,visual=(;colorrange=[-1,1],interpolation=TopoPlots.NullInterpolator(),enlarge=0.9,markersize=20),layout=(;showLegend=false))
	f
end

# ╔═╡ 10d2ee3b-7708-4ad8-af36-6071b21e0cc9
pos3D_to_layout(pos3)

# ╔═╡ Cell order:
# ╠═5451c8fd-c1cf-4088-9e0b-6fed0c388bf7
# ╠═80e36c32-187f-41ba-82eb-d84c22de6d69
# ╠═7b3eca23-cc2a-4212-abc3-70f941afb4d4
# ╠═ea3e73be-2bb6-11ee-0b04-43b39a893537
# ╠═256e9785-9f54-4546-ac51-53c2a22e6c79
# ╠═ba178d91-1d03-40f1-97ea-ec03b8bd29c6
# ╠═c0f10639-eda1-4af5-b877-00406b066de0
# ╠═67470dc9-3282-4462-a675-b00d8a9c9241
# ╠═461827a5-8597-4a05-9201-4cf94af01b58
# ╠═01c13032-2b18-4cc3-8e62-975448e390a1
# ╠═a8cf7a53-6d5e-4400-a3bd-80034a7ed5f6
# ╠═15533746-a53e-4694-b8ca-285bc20f83c5
# ╠═b2efb84a-1f96-4671-b25e-65001cba12a2
# ╠═df5ff6e9-505f-4a25-97aa-e19be6286c8f
# ╠═ca9835eb-0a68-461e-884f-9ca75a584d92
# ╠═85de4fff-8eb3-4193-b11d-a545d4f60a05
# ╠═a91e1f64-fd06-4648-9352-4533eff5aaaa
# ╠═1b025463-936f-432c-91a1-056d0d9b9bcd
# ╠═3f0fa6da-3790-4264-beba-4785eb1bb0ee
# ╠═933f3050-4c0e-44b3-89e7-4dc59591128d
# ╠═93dc3a57-6b20-4fe8-abf8-b54ef7a8ab7e
# ╠═5c14e245-6b95-4c4d-85f6-bfbff95ca013
# ╠═ec1915aa-8c07-400c-ad09-2637a74aceee
# ╠═23dca8b4-9166-41fc-bf42-9d6d57f29da6
# ╠═d4c2e872-2bad-44ce-8a9a-42b549464678
# ╠═e0c29a25-1ccd-455b-b99b-fa93c72310d4
# ╠═6f3fb600-013c-4b18-92e8-fe6c0990f0a1
# ╠═10d2ee3b-7708-4ad8-af36-6071b21e0cc9
# ╠═8c70f1c1-313c-4b3b-b4e7-c14818ec9f57
# ╠═6d9c9e59-242e-4021-a972-db57b1b4f58b
# ╠═95426b22-deb7-4b58-bb43-67c368cb9ab9
# ╠═eb3ed1d4-6ad7-4807-8a7a-10313b11b067
# ╠═23f118e1-ceed-407f-9063-f0c49138077b
# ╠═6539620f-7d85-40c4-b5f1-dda42bc9e3e9
# ╠═16369ac8-6cd4-481c-b2dc-b2d884afbfe1
# ╠═cb8b03b7-6457-4fa1-ab4a-84bd1faffbf4
# ╠═d42c85dd-ecb7-4e97-87fa-7dbd1746102c
# ╠═5548c28e-f67f-4873-9f90-d91ba0aaa42b
# ╠═776e0206-91ee-4800-83ec-8b6bdb06505a
# ╠═03462e09-692b-47e0-96c0-bc730fcaf200
# ╠═8513fc7f-cd5a-4ea3-b131-c1bcbcfb4878

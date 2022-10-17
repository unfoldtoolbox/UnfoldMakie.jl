
using TopoPlots
"""
Makes use of TopoPlots example data (originating from eegvis matlab toolbox).
Returns tidy DataFrame with two conditions, 64 channels and 800ms of data. This is an average over many subjects.
"""
function example_data()

	data,chanlocs = TopoPlots.example_data();
	df = DataFrame(estimate=Float64[],time=Float64[],channel=Int64[],coefname=String[],topoPositions=[],se=Float64[],pval=Float64[])
	pos = TopoPlots.points2mat(chanlocs)
	for ch = 1:size(data,1)
		for t = 1:size(data,2)
			append!(df,DataFrame(estimate=data[ch,t,1],se=data[ch,t,2],pval=data[ch,t,3],time=t,channel=ch,coefname="A",topoPositions=(pos[1,ch],pos[2,ch])))
			
			
		end
	end
df.time = range(-0.3,0.5,step=1/500)[Int.(df.time)]

dftmp = deepcopy(df)
dftmp.estimate .= 0.5 .* dftmp.estimate .+ 0.1.*rand(nrow(df)) .- 0.05
dftmp.coefname .= "B"
df = vcat(df,dftmp)

return df
end
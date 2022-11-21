### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ a979aa82-4b9d-11ed-1469-978ebad92bc3
begin
    using Pkg
    Pkg.activate("..")
end

# ╔═╡ c2e68f1d-23a6-4d8a-bcf2-9ba1620869cf
using Revise

# ╔═╡ cd201ca2-6256-48af-8184-8744ab24028f
using UnfoldMakie

# ╔═╡ 87c04057-55cd-4772-918f-9e29ec12e6ea
using CairoMakie

# ╔═╡ 6219f1b9-1e5b-4e07-81c9-867022baa554
using TopoPlots

# ╔═╡ 16636c28-95e4-4e8e-aa8d-6a0807f15a74
using Unfold

# ╔═╡ ea4472d4-d6f4-4270-9483-405d27f09be3
using DataFrames

# ╔═╡ d6afa7aa-eb8a-4a85-b378-37c01408756d
data, chanlocs = TopoPlots.example_data();

# ╔═╡ b1a9cd37-f22e-471c-bd7f-c0e508d26adc
begin
    df = DataFrame(estimate=Float64[], time=[], channel=[], coefname=[], topoPositions=[], se=[])
    pos = TopoPlots.points2mat(chanlocs)
    for ch = 1:size(data, 1)
        for t = 1:size(data, 2)
            append!(df, DataFrame(estimate=data[ch, t, 1], se=data[ch, t, 1], time=t, channel=ch, coefname="A", topoPositions=(pos[1, ch], pos[2, ch])))


        end
    end
    dftmp = deepcopy(df)
    dftmp.estimate .= 0.5 .* dftmp.estimate .+ 0.1 .* rand(nrow(df)) .- 0.05
    dftmp.coefname .= "B"
    df = vcat(df, dftmp)
end

# ╔═╡ 5fb731af-d004-4e01-a459-b8ccc5362613
UnfoldMakie.plot_butterfly(df[df.coefname.=="A", :]; setExtraValues=(:topoLegend => true,), setMappingValues=(:category => :coefname,))#,topoPositions=chanlocs))

# ╔═╡ 3f25224f-e2a2-4df3-9ee5-94c7e5b3760b
UnfoldMakie.plot_erp(df[df.channel.==32, :])

# ╔═╡ 01457325-fde5-4c61-95c7-9467175ef4a7


# ╔═╡ 4182b4dc-f6bb-4de2-883e-9db5c5e592b8
UnfoldMakie.plot_topo(df[(df.time.==230).&&(df.coefname.=="A"), :])

# ╔═╡ 3f7decce-5f15-4298-a304-f42967cb0f9b
UnfoldMakie.plot_paraCoord(df, collect(20:30), setMappingValues=(:category => :coefname,))

# ╔═╡ Cell order:
# ╠═a979aa82-4b9d-11ed-1469-978ebad92bc3
# ╠═cd201ca2-6256-48af-8184-8744ab24028f
# ╠═87c04057-55cd-4772-918f-9e29ec12e6ea
# ╠═6219f1b9-1e5b-4e07-81c9-867022baa554
# ╠═d6afa7aa-eb8a-4a85-b378-37c01408756d
# ╠═16636c28-95e4-4e8e-aa8d-6a0807f15a74
# ╠═ea4472d4-d6f4-4270-9483-405d27f09be3
# ╠═b1a9cd37-f22e-471c-bd7f-c0e508d26adc
# ╠═5fb731af-d004-4e01-a459-b8ccc5362613
# ╠═3f25224f-e2a2-4df3-9ee5-94c7e5b3760b
# ╠═01457325-fde5-4c61-95c7-9467175ef4a7
# ╠═4182b4dc-f6bb-4de2-883e-9db5c5e592b8
# ╠═3f7decce-5f15-4298-a304-f42967cb0f9b
# ╠═c2e68f1d-23a6-4d8a-bcf2-9ba1620869cf

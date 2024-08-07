dat, pos = TopoPlots.example_data()

dat = dat[:, :, 1]
pos = pos[1:30]

#df, pos = example_data("TopoPlots.jl")

@testset "Channel image: 3 arguments, data as Matrix" begin
    plot_channelimage(dat, pos, raw_ch_names;)
end

@testset "Channel image: 4 arguments, data as Matrix" begin
    f = Figure()
    plot_channelimage!(f, dat, pos, raw_ch_names;)

end

#= @testset "Channel image: 3 arguments, data as DataFrame" begin
    plot_channelimage(df, pos, raw_ch_names;)
end =#

@testset "Channel image: error of unequal length of pos and ch_names" begin
    err1 = nothing
    t() = error(plot_channelimage(dat, pos[1:10], raw_ch_names;))

    try
        t()
    catch err1
    end
end

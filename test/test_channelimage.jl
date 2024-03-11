dat, pos = TopoPlots.example_data()
dat = dat[:, :, 1]
pos = pos[1:30]

@testset "channel image basic" begin
    plot_channelimage(dat, pos, raw_ch_names;)
end

@testset "channel image with Figure" begin
    f = Figure()
    plot_channelimage!(f, dat, pos, raw_ch_names;)

end

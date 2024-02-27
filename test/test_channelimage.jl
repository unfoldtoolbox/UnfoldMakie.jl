data, pos = TopoPlots.example_data()
data = data[:, :, 1]
pos = pos[1:30]

@testset "channel image basic" begin
    plot_channelimage(data, pos, raw_ch_names;)
end

@testset "channel image with Figure" begin
    f = Figure()
    plot_channelimage!(f, data, pos, raw_ch_names;)

end

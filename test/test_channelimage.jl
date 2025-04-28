dat, pos = TopoPlots.example_data()

dat = dat[:, :, 1]
pos = pos[1:30]

df, pos2 = UnfoldMakie.example_data("TopoPlots.jl")


@testset "Channel image: 3 arguments, data as Matrix" begin
    plot_channelimage(dat[1:30, :], pos, channels_30;)
end

@testset "Channel image: 4 arguments, data as Matrix" begin
    f = Figure()
    plot_channelimage!(f, dat[1:30, :], pos, channels_30;)

end

@testset "Channel image: 3 arguments, data as DataFrame" begin
    f = Figure(size = (400, 800))
    array = [string(i) for i = 1:64]
    df2 = unstack(df[:, [:estimate, :time, :channel]], :channel, :time, :estimate)
    select!(df2, Not(:channel))
    plot_channelimage!(f, df2, pos2, array;)
end

@testset "Channel image: error of unequal length of pos and ch_names" begin
    err1 = nothing
    t() = error(plot_channelimage(dat[1:30, :], pos[1:10], channels_30;))

    try
        t()
    catch err1
    end
end

@testset "Channel image: sorting by y" begin
    plot_channelimage(
        dat[1:30, :],
        pos,
        channels_30;
        sorting_variables = [:y],
        sorting_reverse = [:true],
    )
end

@testset "Channel image: sorting by ch_names" begin
    plot_channelimage(
        dat[1:30, :],
        pos,
        channels_30;
        sorting_variables = [:ch_names],
        sorting_reverse = [:true],
    )
end

@testset "Channel image: error of unequal sorting_variables and sorting_reverse" begin
    err1 = nothing
    t() = error(plot_channelimage(dat[1:30, :], pos, channels_30; sorting_variables = [:y]))
    try
        t()
    catch err1
    end
end

@testset "Channel image: error of unequal data and sorting_reverse" begin
    err1 = nothing
    t() = error(plot_channelimage(dat, pos, channels_30; sorting_variables = [:y]))
    try
        t()
    catch err1
    end
end

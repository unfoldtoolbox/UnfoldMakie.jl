@testset "every bundled montage will load correctly" begin
    for name in UnfoldMakie.list_montages()
        m = UnfoldMakie.get_montage(name)
        @test !isempty(m.labels)
        @test length(m.labels) == length(m.positions)
        @test all(p -> all(isfinite, p), m.positions)
    end
end

@testset "list_montages: names, no extensions, unique" begin
    ms = UnfoldMakie.list_montages()
    @test "standard_1020" in ms
    exts = (".txt", ".tsv", ".sfp", ".elc", ".csd")
    @test all(m -> !any(e -> endswith(m, e), exts), ms)  
    @test length(ms) == length(unique(ms))         #no duplicates
end

#test for every format, inc. of .csd

@testset ".txt format (biosemi64)" begin
    m = UnfoldMakie.get_montage("biosemi64")
    p = Dict(uppercase(l) => pos for (l, pos) in zip(m.labels, m.positions))
    @test isapprox(p["CZ"][1], 0.0; atol = 1e-3) && isapprox(p["CZ"][2], 0.0; atol = 1e-3)
    @test p["FPZ"][2] > 0.5
end

@testset ".tsv format (standard_1020)" begin
    m = UnfoldMakie.get_montage("standard_1020")
    p = Dict(uppercase(l) => pos for (l, pos) in zip(m.labels, m.positions))
    @test isapprox(p["CZ"][1], 0.0; atol = 1e-4) && isapprox(p["CZ"][2], 0.0; atol = 1e-4)
    @test p["FPZ"][2] > 0.5    #front
    @test p["OZ"][2]  < -0.5   #back
    @test p["T8"][1]  > 0.5     #right
    @test p["T7"][1]  < -0.5   #left
end

@testset ".sfp format (GSN-HydroCel-32)" begin
    m = UnfoldMakie.get_montage("GSN-HydroCel-32")
    i = findfirst(==("Cz"), m.labels)
    @test i !== nothing
    @test isapprox(m.positions[i][1],0.0; atol = 1e-3) && isapprox(m.positions[i][2], 0.0; atol = 1e-3)
end

@testset ".elc format (colin27_1020)" begin
    m = UnfoldMakie.get_montage("colin27_1020")
    p = Dict(uppercase(l) => pos for (l, pos) in zip(m.labels, m.positions))
    @test p["FPZ"][2] > 0.5   #front
    @test p["OZ"][2]  < -0.5  #back
    @test p["T8"][1]  > 0.5   #right
    @test p["T7"][1]  < -0.5  #left
end

@testset ".csd format (EGI_256)" begin
    m = UnfoldMakie.get_montage("EGI_256")
    @test length(m.labels) == 256
    p = Dict(l => pos for (l, pos) in zip(m.labels, m.positions))
    @test p["E31"][2] > 0.5  #note E31 is front electrode --> +y
end

#API

@testset "get_montage: unknown name errors" begin
    @test_throws ErrorException UnfoldMakie.get_montage("not_a_real_montage")
end

@testset "standard_positions: case-insensitive, order" begin
    pos = UnfoldMakie.standard_positions(["cz", "Fpz", "OZ"], "standard_1020")
    @test length(pos) == 3
    @test isapprox(pos[1][1], 0.0; atol = 1e-4) && isapprox(pos[1][2], 0.0; atol = 1e-4)  # cz center
    @test pos[2][2] > 0.5   
    @test pos[3][2] < -0.5
end

@testset "standard_positions: missing label errors" begin
    @test_throws ErrorException UnfoldMakie.standard_positions(["Cz", "NOSUCH"], "standard_1020")
end
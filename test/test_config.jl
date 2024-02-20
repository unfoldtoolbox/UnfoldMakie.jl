@testset "config kwargs" begin
    cfg = PlotConfig()
    UnfoldMakie.config_kwargs!(cfg; visual = (; bla = :blub))
    @test cfg.visual.bla == :blub

    # now test that you cannot forget the ; - that is, cant forget to specify a NamedTuple
    @test_throws AssertionError UnfoldMakie.config_kwargs!(cfg; visual = (bla = :blub))

end

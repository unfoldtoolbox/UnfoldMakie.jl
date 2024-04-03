@testset "config kwargs" begin
    cfg = PlotConfig()
    UnfoldMakie.config_kwargs!(cfg; visual = (; bla = :blub))
    @test cfg.visual.bla == :blub

    # What if you forget `;` - that is, forget to specify a `NamedTuple`.
    @test_throws AssertionError UnfoldMakie.config_kwargs!(cfg; visual = (bla = :blub))
end

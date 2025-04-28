using Unfold: eventnames
using AlgebraOfGraphics: group
m = UnfoldMakie.example_data("UnfoldLinearModel")
res_effects = effects(Dict(:continuous => -5:0.5:5), m)
res_effects2 = effects(Dict(:condition => ["car", "face"], :continuous => -5:5), m)

@testset "Effect plot" begin
    plot_erp(res_effects; mapping = (; y = :yhat, color = :continuous, group = :continuous))
end

@testset "Effect plot: faceted by channels" begin
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous => nonnumeric, col = :channel),
        legend = (; nbanks = 2),
    )
end

@testset "Effect plot: no colorbar and yes legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = true, use_colorbar = false),
    )
end

@testset "Effect plot: yes colorbar and no legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = false, use_colorbar = true),
    )
end

@testset "Effect plot: yes colorbar and yes legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = true, use_colorbar = true),
    )
end

@testset "Effect plot: no colorbar and no legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = false, use_colorbar = false),
    )
end

@testset "Effect plot: move legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        legend = (; valign = :bottom, halign = :right),
        axis = (
            title = "Marginal effects",
            titlegap = 12,
            xlabel = "Time [s]",
            ylabel = "Amplitude [μV]",
            xlabelsize = 16,
            ylabelsize = 16,
            xgridvisible = false,
            ygridvisible = false,
        ),
    )
end

@testset "Effect plot: xlabelvisible is not working" begin
    eff_same = effects(Dict(:condition => ["car", "face"], :duration => 200), m)

    plot_erp(results; axis = (; xlabelvisible = false, xticklabelsvisible = false))
    plot_erp(
        eff_same;
        mapping = (; col = :condition, color = :time),
        axis = (;
            xlabel = "test",
            titlevisible = false,
            xlabelvisible = false,
            ylabelvisible = false,
            yticklabelsvisible = false,
            xticklabelsvisible = false,
        ),
    )
end

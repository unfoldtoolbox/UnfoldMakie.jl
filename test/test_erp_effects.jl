using Unfold: eventnames
using AlgebraOfGraphics: group
include("../docs/example_data.jl")
m = example_data("UnfoldLinearModel")
res_effects = effects(Dict(:continuous => -5:0.5:5), m)
res_effects2 = effects(Dict(:condition => ["car", "face"], :continuous => -5:5), m)

@testset "Effect plot" begin #where is legend here??
    plot_erp(
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous),
        legend = (; nbanks = 2),
        layout = (; legend_position = :right),
        categorical_color = false,
        categorical_group = true,
    )
end

@testset "Effect plot: faceted" begin #bug
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    plot_erp(res_effects; mapping = (; y = :yhat, color = :continuous, col = :channel))
end

@testset "Effect plot: faceted channels" begin #bug
    res_effects = effects(Dict(:continuous => -5:0.5:5), m)
    res_effects.channel = push!(repeat(["1", "2"], 472), "1")
    #res_effects.channel = float.(push!(repeat([1, 2], 472), 1))
    plot_erp(res_effects; mapping = (; y = :yhat, group = :channel, col = :channel))
end

@testset "Effect plot: no colorbar and legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; show_legend = true, use_legend = false, use_colorbar = false),
        categorical_color = false,
    )
end

@testset "Effect plot: no colorbar" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = true, use_colorbar = false),
        categorical_color = false,
    )
end

@testset "Effect plot: no legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = false, use_colorbar = true),
        categorical_color = false,
    )
end

@testset "Effect plot: no colorbar and no legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = false, use_colorbar = false),
        categorical_color = false,
    )
end

@testset "Effect plot: yes colorbar and yes legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        layout = (; use_legend = true, use_colorbar = true),
        categorical_color = false,
    )
end

@testset "Effect plot: move legend" begin
    plot_erp(
        res_effects2;
        mapping = (; color = :continuous, linestyle = :condition, group = :continuous),
        legend = (; valign = :bottom, halign = :right, tellwidth = false),
        categorical_color = false,
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
    plot_erp(
        res_effects2;
        mapping = (; col = :eventname),#, color = :condition), why it doesn't work???
        axis = (;
            titlevisible = false,
            xlabelvisible = false,
            ylabelvisible = false,
            yticklabelsvisible = false,
        ),
    )
end

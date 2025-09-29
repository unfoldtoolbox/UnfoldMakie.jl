using Unfold: coefnames
# # Complex figures

#=
This section discusses how users can incorporate multiple plots into a single figure.
=#

# # Setup
# **Library load**

using UnfoldMakie
using CairoMakie
using DataFramesMeta
using UnfoldSim
using Unfold
using MakieThemes
using TopoPlots


# **Data input**
topo_df, positions = UnfoldMakie.example_data("TopoPlots.jl")
topo_array, _ = TopoPlots.example_data()
toposeries_df = UnfoldMakie.eeg_array_to_dataframe(topo_array[:, :, 1], string.(1:length(positions)));
channels_30 = UnfoldMakie.example_montage("channels_30");

uf_deconv = UnfoldMakie.example_data("UnfoldLinearModelContinuousTime")
uf = UnfoldMakie.example_data("UnfoldLinearModel");
results = coeftable(uf)
uf_5chan = UnfoldMakie.example_data("UnfoldLinearModelMultiChannel");

dat_e, evts, times = UnfoldMakie.example_data("sort_data")
d_singletrial, _ = UnfoldSim.predef_eeg(; return_epoched = true);

m = UnfoldMakie.example_data("UnfoldLinearModel") ;
results = coeftable(m);
results.coefname =
    replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car");
results = filter(row -> row.coefname != "continuous", results);

df_circ = DataFrame(
    :estimate => eachcol(Float64.(topo_array[:, 100:40:300, 1])),
    :circular_variable => [0, 50, 80, 120, 180, 210],
    :time => 100:40:300,
);
df_circ = flatten(df_circ, :estimate);

# # Basic complex figure

#=
By using the !-version of the plotting function and inserting a grid position instead of an entire figure, we can create complex plot that combines several figures.
=#
# We will start by creating a figure with `Makie.Figure`.

# Now any plot can be added to `f` by placing a grid position, such as `f[1, 1]`.
# Also we used a specified theme `fresh`.

f = Figure(size = (750, 500))
with_theme(theme_ggthemr(:fresh)) do
    plot_erp!(f[1, 1], coeftable(uf_deconv); mapping = (; color = :coefname => "Conditions"))
    plot_erp!(
        f[1, 2],
        effects(Dict(:condition => ["car", "face"]), uf_deconv),
        mapping = (; y = :yhat, color = :condition => "Conditions"),
    )
    plot_butterfly!(f[2, 1:2], topo_df; positions = positions,
        topo_attributes = (; label_scatter = (; markersize = 5)),
        topo_axis = (; height = Relative(0.5), width = Relative(0.5)))
end
f

# # A very complex figure
#=
We can create a large figure with any type of plot using predefined data.

With so many plots at once, it's better to set a fixed resolution in your image to arrange the plots evenly.
=#

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
begin
    f = Figure(size = (2000, 2000))

    plot_butterfly!(f[1, 1:3], topo_df; positions = positions)

    pvals = DataFrame(
        from = [0.1, 0.15],
        to = [0.2, 0.5], # if coefname not specified, line should be black
        coefname = ["(Intercept)", "category: face"],
    )
    plot_erp!(f[2, 1:2], results, significance = pvals, stderror = true)

    plot_designmatrix!(f[2, 3], designmatrix(uf))

    plot_topoplot!(f[3, 1], topo_array[:, 150, 1]; positions = positions)
    plot_topoplotseries!(
        f[4, 1:3],
        topo_df;
        bin_width = 0.1,
        positions = positions,
        mapping = (; label = :channel),
    )

    res_effects = effects(Dict(:continuous => -5:0.5:5), uf_deconv)

    plot_erp!(
        f[2, 4:5],
        res_effects;
        mapping = (; y = :yhat, color = :continuous, group = :continuous => nonnumeric),
        legend = (; nbanks = 2),
    )

    plot_parallelcoordinates(f[3, 2:3], uf_5chan; mapping = (; color = :coefname))

    plot_erpimage!(f[1, 4:5], times, d_singletrial)
    plot_circular_topoplots!(
        f[3:4, 4:5],
        topo_df[in.(topo_df.time, Ref(-0.3:0.1:0.5)), :];
        positions = positions,
        predictor = :time,
        predictor_bounds = [-0.3, 0.5],
    )
end
# ```@raw html
# </details >
# ```
f

# # Complex figure in two columns and with background color

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
function complex_figure3(topo_df, topo_array, positions, toposeries_df, channels_30, results, df_circ, dat_e, evts, times)
    f = Figure(size = (1200, 1700))
    (ga, gc, ge, gg, gi) = (f[1, 1], f[2, 1], f[3, 1], f[4, 1], f[5:6, 1])
    (gb, gd, gf, gh, gj) = (f[1, 2], f[2, 2], f[3, 2], f[4, 2], f[5:6, 2])

    plot_erp!(
        ga,
        results;
        :stderror => true,
        mapping = (; color = :coefname => "Conditions"),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]"),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    plot_butterfly!(
        gb,
        topo_df;
        positions = positions,
        topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]"),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)
    plot_topoplot!(
        gc,
        topo_array[:, 340, 1];
        positions = positions,
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; xlabel = "[340 ms]"),
    )

    plot_topoplotseries!(
        gd,
        toposeries_df;
        bin_width = 80,
        positions = positions,
        visual = (label_scatter = false, contours = false),
        layout = (; use_colorbar = true),
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]"),
    )

    plot_erpgrid!(
        ge,
        topo_array[:, :, 1],
        positions;
        indicator_grid_axis = (;
            ylim = [-0.05, 0.6], xlim = [-0.04, 1], text_x_kwargs = (; text = "s"),
            text_y_kwargs = (; text = "µV"),
        ),
        axis = (; backgroundcolor = colorant"#F4F3EF",),
    )

    plot_erpimage!(
        gf,
        times,
        dat_e;
        sortvalues = evts.Δlatency,
        axis = (; xlabel = "Time [ms]"),
    )
    m1 = UnfoldMakie.example_data("UnfoldLinearModelwith1Spline")
    plot_splines!(
        gg,
        m1;
        spline_axis = (; backgroundcolor = colorant"#F4F3EF"),
        density_axis = (; backgroundcolor = colorant"#F4F3EF"),
    )

    topo_df.coefname .= "B" # create a second category
    topo_df.estimate .+= rand(length(topo_df.estimate)) * 0.1
    plot_parallelcoordinates(
        gh,
        subset(topo_df, :channel => x -> x .< 8, :time => x -> x .< 0);
        mapping = (; color = :coefname),
        normalize = :minmax,
        ax_labels = ["FP1", "F3", "F7", "FC3", "C3", "C5", "P3", "P7"],
        axis = (; backgroundcolor = colorant"#F4F3EF", ylabel = "Time [ms]"),
    )
  
    plot_circular_topoplots!(
        gi,
        df_circ;
        positions = positions,
        center_label = "Time [s]",
        predictor = :time,
        topo_attributes = (; label_scatter = false,),
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; backgroundcolor = colorant"#F4F3EF"),
        predictor_bounds = [80, 320],
        colorbar = (; height = 180),
    )
    plot_channelimage!(
        gj,
        topo_array[1:30, :, 1],
        positions[1:30],
        channels_30;
        axis = (; xlabel = "Time [ms]"),
    )

    for (label, layout) in
        zip(
        ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"],
        [ga, gb, gc, gd, ge, gf, gg, gh, gi, gj],
    )
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (20, 20, 22, 0),
            halign = :right,
        )
    end
    f
end
# ```@raw html
# </details >
# ```
with_theme(Theme(; backgroundcolor = colorant"#F4F3EF")) do
    complex_figure3(topo_df, data, positions, toposeries_df, channels_30, results, df_circ, dat_e, evts, times)
end

# # Complex figure in four columns and with background color

# ```@raw html
# <details>
# <summary>Click to expand</summary>
# ```
results = coeftable(m)
results.coefname =
    replace(results.coefname, "condition: face" => "face", "(Intercept)" => "car")
results = filter(row -> row.coefname != "continuous", results)

function complex_figure4(topo_df, topo_array, positions, toposeries_df, channels_30, results, df_circ, dat_e, evts, times)
    f = Figure(size = (1800, 1000))

    (ga, gb, gc, gd) = (f[1, 1], f[1, 2], f[1, 3], f[1, 4])
    (ge, gf, gg, gh) = (f[2, 1], f[2, 2], f[2, 3], f[2, 4])

    plot_erp!(
        ga,
        results;
        :stderror => true,
        mapping = (; color = :coefname => "Conditions:"),
        legend = (;
            orientation = :horizontal,
            titleposition = :left,
            position = :bottom,
            labelsize = 18,
            titlesize = 20,
            nbanks = 2,
        ),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabel = "Time [ms]",  width = 350,  
            xlabelsize = 24, ylabelsize = 24, xticklabelsize = 18, yticklabelsize = 18),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)

    plot_butterfly!(
        gb,
        topo_df;
        positions = positions,
        topo_axis = (; height = Relative(0.4), width = Relative(0.4)),
        axis = (; backgroundcolor = colorant"#F4F3EF",
            xlabel = "Time [ms]", xlabelsize = 24, ylabelsize = 24, xticklabelsize = 18,
            yticklabelsize = 18),
    )
    hlines!(0, color = :gray, linewidth = 1)
    vlines!(0, color = :gray, linewidth = 1)

    plot_topoplot!(
        ge,
        topo_array[:, 340, 1];
        positions = positions,
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (;
            xlabel = "[340 ms]",
            backgroundcolor = colorant"#F4F3EF",
            xlabelsize = 24,
            ylabelsize = 24,
        ),
        colorbar = (; vertical = false, width = 180, labelsize = 24, ticklabelsize = 18),
        visual = (; contours = false),
    )

    plot_topoplotseries!(
        gf,
        toposeries_df;
        bin_width = 80,
        nrows = 3,
        positions = positions,
        visual = (label_scatter = false, contours = false),
        layout = (; use_colorbar = true),
        topo_axis = (; backgroundcolor = colorant"#F4F3EF", xlabelsize = 18),
        axis = (;
            xlabelpadding = 70,
            backgroundcolor = colorant"#F4F3EF",
            xlabel = "        Time [ms]",
            xlabelsize = 24,
            ylabelsize = 24,
        ),
        colorbar = (; height = 180, labelsize = 24, ticklabelsize = 18),
    )

    plot_erpgrid!(
        gc,
        topo_array[:, :, 1],
        positions;
        indicator_grid_axis = (;
            ylim = [-0.05, 0.6], xlim = [-0.07, 1],
            text_x_kwargs = (; text = "s", fontsize = 24),
            text_y_kwargs = (; text = "µV", fontsize = 24),
        ),
        axis = (; backgroundcolor = colorant"#F4F3EF",),
        colorbar = (; height = 180, labelsize = 24, ticklabelsize = 18),
    )

    plot_erpimage!(
        gd,
        times,
        dat_e;
        sortvalues = evts.Δlatency,
        axis = (;
            xlabel = "Time [ms]",
            xlabelsize = 24,
            ylabelsize = 24,
            xticklabelsize = 18,
            yticklabelsize = 18,
        ),
        colorbar = (; height = 180, labelsize = 24, ticklabelsize = 18),
    )

    plot_circular_topoplots!(
        gg,
        df_circ;
        positions = positions,
        center_label = "Time [ms]",
        predictor = :time,
        topo_attributes = (; label_scatter = false, contours = false),
        topo_axis = (; backgroundcolor = colorant"#F4F3EF"),
        axis = (; backgroundcolor = colorant"#F4F3EF", xlabelsize = 24, ylabelsize = 24),
        predictor_bounds = [80, 320],
        colorbar = (; height = 180, labelsize = 24, ticklabelsize = 18),
    )
    plot_channelimage!(
        gh,
        topo_array[1:30, :, 1],
        positions[1:30],
        channels_30;
        axis = (;
            xlabel = "Time [ms]",
            xlabelsize = 24,
            ylabelsize = 24,
            xticklabelsize = 18,
            yticklabelsize = 18,
        ),
        colorbar = (; height = 180, labelsize = 24, ticklabelsize = 18),
    )
  
    for (label, layout) in
        zip(
        ["A", "B", "C", "D", "E", "F", "G", "H"],
        [ga, gb, gc, gd, ge, gf, gg, gh],
    )
        Label(
            layout[1, 1, TopLeft()],
            label,
            fontsize = 26,
            font = :bold,
            padding = (20, 20, 22, 0),
            halign = :right,
        )
    end
    f
end
# ```@raw html
# </details >
# ```
f = with_theme(Theme(; backgroundcolor = colorant"#F4F3EF")) do
    complex_figure4(topo_df, topo_array, positions, toposeries_df, channels_30, results, df_circ, dat_e, evts, times)
end


#save("complex_figure4.png", f)

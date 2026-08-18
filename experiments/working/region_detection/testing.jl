include("geometry.jl")
include("scoring.jl")
include("plotting.jl")
include("../stimuli_data.jl")
include("../plot_helpers/vsp_sup.jl")


test = load_erp_subject("MMN"; subject = 20, timepoint = 96, condition = 1)
#test = load_erp_subject("N2pc"; subject = 1, timepoint = 96, condition = 1)

begin
    t = _subject_abs_snr(test)
    f = plot_topoplot(
        t;
        labels = test.labels,
        axis = (; xlabel = ""),
        visual = (;
            contours = true,
            colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        ),
        colorbar = (;
            labelsize = 24,
            ticklabelsize = 18,
            height = 350,
            label = "SNR",#"|estiamte|/se"#
        ),
    )
end
positions = TopoPlots.labels2positions(test.labels)

begin
    f = plot_topoplot(
        test.abs_t;
        labels = test.labels,
        axis = (; xlabel = ""),
        visual = (;
            contours = true,
            colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
        ),
        colorbar = (; labelsize = 24, ticklabelsize = 18, height = 350, label = "SNR"),
    )
    ax = f.content[2]
    overlay_region_polygons!(
        ax,
        TOPO_REGIONS;
        head_center = (0.0f0, -0.08f0),
        head_radius = 1.33,
        template_center = (150.0, 150.0),
        template_radius = 150.0,
        fontsize = 20,
    )
    f
end
begin
    f = plot_topoplot(
        test.abs_t;
        labels = test.labels,
        axis = (; xlabel = ""),
        visual = (;
            contours = false,
            colormap = cgrad([:white, :white]),
        ),
        layout = (; use_colorbar = false),
        colorbar = (; labelsize = 24, ticklabelsize = 18, height = 350, label = "SNR"),
    )
    ax = f.content[2]
    overlay_region_polygons!(
        ax,
        TOPO_REGIONS;
        head_center = (0.0f0, -0.08f0),
        head_radius = 1.33,
        template_center = (150.0, 150.0),
        template_radius = 150.0,
        fontsize = 20,
    )
    f
   # save("experiments/figures/region_overlay_electrodes.svg", f)
end

# target topoplot for illustration
begin
    test = load_erp_subject("N2pc"; subject = 1, timepoint = 96, condition = 1)
    f = Figure()
    ax = Axis(f[1, 1])
    ax.title = "Target topoplot"
    ax.titlesize = 26
    hidedecorations!(ax)
    hidespines!(ax)
    plot_topoplot!(
        f,
        _subject_abs_snr(test);
        labels = test.labels,
        axis = (; xlabel = ""),
        colorbar = (; labelsize = 24, ticklabelsize = 18),
    )
   # save("stimuli/SNR0.png", f)
end

# voltafm noise and SNR plots for illustration
begin
    test = load_erp_subject("N2pc"; subject = 3, timepoint = 80, condition = 2)
    f = triple_SNR(test; sew = 2)
   # save("stimuli/triple_SNR.png", f)
end

# single plot, 1-8 scores, with score colorbar
begin
    f = plot_subject_region_weights(
        "N2pc";
        subject = 1,
        timepoint = 96,
        condition = 1,
        scoring = (; score_transform = identity, agg = :mean, n_bins = 8, binning = :quantile),
        topoplot = (;
            show_labels = true,
            template_radius = 126.0f0,
            region_center = (0.0f0, 0.08f0),
            fontsize = 26,
            fontcolor = :white,
        ),
        title_cfg = (; title = "Example SNR topoplot with 32 regions", titlesize = 26),
        colorbar = (;
            label = "Region score",
            labelsize = 22,
            ticklabelsize = 18,
            row_height = 0.18,
            width = 300,
        ),
    )
    f
   # save("stimuli/SNR.png", f)
end

function plot_subject_bivariate_and_region_scores(
    task;
    subject,
    timepoint,
    condition,
    agg = :mean,
    n_bins = 8,
    binning = :quantile,
    uncert_label = "SE",
    show_labels = true,
    palette = Dict(i => cgrad(:RdYlBu, 8; categorical = true, rev = true)[i] for i in 1:8),
)
    test = load_erp_subject(
        task;
        subject = subject,
        timepoint = timepoint,
        condition = condition,
    )
    est = test.estimate
    snr = _subject_abs_snr(test)

    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, snr; labels = test.labels)
    xg, yg, Z, Zmask = extract_topoplot_grid(h)

    rows_t = region_weights_from_grid(
        xg,
        yg,
        Zmask,
        TOPO_REGIONS;
        agg = agg,
        n_bins = n_bins,
        binning = binning,
    )
    weights = Dict(r.label => r.weight for r in rows_t)

    f = Figure(size = (500, 660), figure_padding = (12, 12, 18, 12))
    gl = f[1, 1] = GridLayout()
    colgap!(gl, 24)

    Label(
        f[0, 1:2],
        "$task | subject $subject | $(timepoint) ms | condition $condition";
        fontsize = 28,
        font = :bold,
    )

    plot_bivariate_corner!(
        gl[1, 1],
        est,
        test.se;
        labels = test.labels,
        uncert_label = uncert_label,
       # show_colorbox = true,
    )

    _, ax = plot_region_weight_topoplot!(
        gl[2, 1],
        weights;
        show_labels = show_labels,
        template_radius = 126.0f0,
        region_center = (0.0f0, 0.08f0),
        fontsize = 22,
        fontcolor = :white,
        palette = palette,
    )
    ax.title = "Region scores"
    ax.titlesize = 22

    return f
end

mmn20_bivariate_region_scores = plot_subject_bivariate_and_region_scores(
    "MMN";
    subject = 20,
    timepoint = 96,
    condition = 3,
)

plot_subject_bivariate_and_region_scores(
    "P3";
    subject = 4,
    timepoint = 129,
    condition = 1,
)

## Idea: we need to find xg, yg, data_interpolated and mask
# not always at the same place

# basefig = Figure()
ax = Axis(fig[1, 1])
h = eeg_topoplot!(ax, test.abs_t; labels = test.labels)
fig

# good for search
typeof(h)
propertynames(h)
fieldnames(typeof(h))
dump(h; maxdepth = 2)



tp = h.plots[1]
xg = tp.xg[]
yg = tp.yg[]
Z = tp.data_interpolated[]
M = tp.mask[]
Zmask = M .* Z

#typeof(xg), size(Z), typeof(M)
#minimum(Z), maximum(Z)


heatmap(xg, yg, Z)
heatmap(xg, yg, Zmask)



plot_subject_region_weights(
    "N2pc";
    subject = 1,
    timepoint = 96,
    condition = 1,
    scoring = (; score_transform = identity, agg = :mean, n_bins = 8, binning = :quantile),
    colorbar = (;),
)

# creating heatmap from xg, yg, Z 
begin
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel = "", aspect = DataAspect())

    hm = heatmap!(
        ax, xg, yg, Z;
        colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
    )
    fig
end

# single plot, 1-8 scores, no legend
begin
    test = load_erp_subject("N2pc"; subject = 1, timepoint = 96, condition = 1)

    # hidden helper plot only to extract interpolated grid
    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, _subject_abs_snr(test); labels = test.labels)

    tp = h.plots[1]
    xg = tp.xg[]
    yg = tp.yg[]
    Z = tp.data_interpolated[]
    M = tp.mask[]
    Zmask = M .* Z

    rows_t = region_weights_from_grid(
        xg,
        yg,
        Zmask,
        TOPO_REGIONS;
        agg = :mean,
        n_bins = 8,
        binning = :quantile,
    )

    weights = Dict(r.label => r.weight for r in rows_t)

    palette8 = Dict(i => cgrad(:RdYlBu, 8; categorical = true, rev = true)[i] for i = 1:8)

    f, ax = plot_region_weight_topoplot(
        weights;
        show_labels = true,
        template_radius = 126.0f0,
        region_center = (0.0f0, 0.08f0),
        fontsize = 22,
        fontcolor = :black,
        palette = palette8,
    )

    ax.title = "N2pc | subject 1 | 96 ms | condition 1"
    ax.titlesize = 20


    f
end



# ranking regions
ranking = rank_regions(
    positions,
    test.abs_t,
    TOPO_REGIONS;
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    samples = 45,
    agg = :mean,       # or :max
)

top4 = ranking[1:4]
println(top4)

# showing weights of regions
weights = region_weights(
    positions,
    test.abs_t,
    TOPO_REGIONS;
    agg = :mean,
    binning = :equal_width,   # or :quantile
    n_bins = 4,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
)

# single plot, 1-4 scores, no legend
begin
    rows_t = region_weights_from_grid(
        xg,
        yg,
        abs.(Zmask),
        TOPO_REGIONS;
        agg = :mean,
        binning = :equal_width,
    )
    weights = Dict(r.label => r.weight for r in rows_t)
    f, ax = plot_region_weight_topoplot(
        weights;
        show_labels = true,
        template_radius = 126.0f0,
        region_center = (0.0f0, 0.08f0),
        fontsize = 24,
        fontcolor = :red,
    )
    f
end

# single plot, 1-4 scores, with legend
begin
    h = eeg_topoplot!(ax, _subject_abs_snr(test); labels = test.labels)
    tp = h.plots[1]
    xg = tp.xg[]
    yg = tp.yg[]
    Z = tp.data_interpolated[]
    M = tp.mask[]
    Zmask = M .* Z
    rows_t = region_weights_from_grid(
        xg,
        yg,
        Zmask,
        TOPO_REGIONS;
        agg = :mean,
        n_bins = 4,
        binning = :quantile,
    )
    weights = Dict(r.label => r.weight for r in rows_t)
    palette = Dict(1 => :gray90, 2 => :skyblue1, 3 => :deepskyblue3, 4 => :navy)

    f, ax = plot_region_weight_topoplot(
        weights;
        show_labels = true,
        template_radius = 126.0f0,
        region_center = (0.0f0, 0.08f0),
        fontsize = 24,
        fontcolor = :red,
        palette = palette,
    )

    legax = Axis(f[2, 1], title = "Configs: agg = :mean, binning = :quantile")
    hidedecorations!(legax)
    hidespines!(legax)
    limits!(legax, 0, 5.2, 0, 1)

    cols = [palette[1], palette[2], palette[3], palette[4]]
    labs = ["1 = lowest", "2", "3", "4 = highest"]
    xs = [0.6, 1.8, 3.0, 4.2]

    for (x, c, lab) in zip(xs, cols, labs)
        poly!(
            legax,
            Point2f[(x - 0.18, 0.35), (x + 0.18, 0.35), (x + 0.18, 0.65), (x - 0.18, 0.65)];
            color = c,
            strokecolor = :black,
        )
        text!(
            legax,
            x + 0.28,
            0.5;
            text = lab,
            align = (:left, :center),
            fontsize = 18,
            color = :black,
        )
    end
    rowgap!(f.layout, -20)
    rowsize!(f.layout, 2, Auto(0.14))

    f
end

# Compute regions for multiple cases
configs_tasks = [
    (task = "MMN", subjects = [20, 25, 26], timepoint = 96, condition = 3),
    (task = "P3", subjects = [11, 12, 16], timepoint = 128, condition = 1),
    (task = "N170", subjects = [26, 5, 12], timepoint = 105, condition = 2),
]

rks = make_region_key(configs_tasks; n_bins = 4, agg = :mean, binning = :quantile)
rks8 = make_region_key(configs_tasks; n_bins = 8, agg = :mean, binning = :quantile)

# 9 region topopltos with 1-4 scores
begin
    fig = Figure(size = (800, 800))
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, 12)
    rowgap!(gl, 18)

    for (k, row) in enumerate(rks)
        i = cld(k, 3)
        j = mod1(k, 3)

        ax = Axis(gl[i, j], aspect = DataAspect(), title = row.stimulus, titlesize = 20)
        hidedecorations!(ax)
        hidespines!(ax)

        plot_region_weight_topoplot!(
            ax,
            row.weights;
            show_labels = true,
            template_radius = 126.0f0,
            region_center = (0.0f0, 0.08f0),
            fontsize = 18,
            fontcolor = :red,
        )
    end

    fig
end

# 9 region topopltos with 1-8 scores. Preferred
begin
    rks8 = make_region_key(configs_tasks; n_bins = 8, agg = :mean, binning = :quantile)
    fig = Figure(size = (800, 800))
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, 12)
    rowgap!(gl, 18)
    palette8 = Dict(i => cgrad(:RdYlBu, 8; categorical = true, rev = true)[i] for i = 1:8)
    for (k, row) in enumerate(rks8)
        i = cld(k, 3)
        j = mod1(k, 3)

        ax = Axis(gl[i, j], aspect = DataAspect(), title = row.stimulus, titlesize = 20)
        hidedecorations!(ax)
        hidespines!(ax)

        plot_region_weight_topoplot!(
            ax,
            row.weights;
            show_labels = true,
            template_radius = 126.0f0,
            region_center = (0.0f0, 0.08f0),
            fontsize = 18,
            palette = palette8,
            fontcolor = :black,
        )
    end

    fig
end

configs_tasks = [
    (task = "MMN", subjects = [20, 25, 26], timepoint = 96, condition = 3),
    (task = "P3", subjects = [11, 12, 16], timepoint = 128, condition = 1),
    (task = "N170", subjects = [26, 5, 12], timepoint = 105, condition = 2),
]

tests = [
    ("MMN_20", load_erp_subject("MMN"; subject = 20, timepoint = 96, condition = 3)),
    ("MMN_25", load_erp_subject("MMN"; subject = 25, timepoint = 96, condition = 3)),
    ("MMN_26", load_erp_subject("MMN"; subject = 26, timepoint = 96, condition = 3)),
    ("P3_11", load_erp_subject("P3"; subject = 11, timepoint = 128, condition = 1)),
    ("P3_12", load_erp_subject("P3"; subject = 12, timepoint = 128, condition = 1)),
    ("P3_16", load_erp_subject("P3"; subject = 16, timepoint = 128, condition = 1)),
    ("N170_26", load_erp_subject("N170"; subject = 26, timepoint = 105, condition = 2)),
    ("N170_5", load_erp_subject("N170"; subject = 5, timepoint = 105, condition = 2)),
    ("N170_12", load_erp_subject("N170"; subject = 12, timepoint = 105, condition = 2)),
]


# 9 SNR topoplots for illustration
# wrong: use minmax ranges
begin
    f = Figure(size = (1100, 1100))

    for (k, (stim, test)) in enumerate(tests)
        r = div(k - 1, 3) + 1
        c = mod(k - 1, 3) + 1

        tvals = _subject_abs_snr(test)

        plot_topoplot!(
            f[r, c],
            tvals;
            labels = test.labels,
            axis = (; xlabel = "", title = stim),
            colorbar = (; label = "SNR", vertical = false, position = :bottom, width = 180),
            visual = (;
                colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
                contours = true,
            ),
        )
    end

    f
end





##################################
###########################
#####################
# selected subjects

#= # SNR topoplots for investigation
for cfg in configs_tasks3
    rks8 = make_region_key([cfg]; n_bins = 8, agg = :mean, binning = :quantile)
    n_cols = 4
    n_rows = cld(length(rks8), n_cols)

    fig = Figure(size = (1600, 320 + 360 * n_rows), figure_padding = (10, 10, 24, 24))
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, 12)
    rowgap!(gl, 18)

    for (k, row) in enumerate(rks8)
        i = cld(k, n_cols)   # max 12 selected subjects -> 2x6 layout
        j = mod1(k, n_cols)

        ax = Axis(gl[i, j], aspect = DataAspect(), title = row.stimulus, titlesize = 36)
        hidedecorations!(ax)
        hidespines!(ax)

        plot_region_weight_topoplot!(
            ax,
            row.weights;
            show_labels = true,
            template_radius = 126.0f0,
            region_center = (0.0f0, 0.08f0),
            fontsize = 26,
            palette = palette8,
            fontcolor = :white,
        )
    end

    figs[cfg.task] = fig
    # save("$(cfg.task)_selected_region_topoplots.png", fig)
end
figs["MMN"]
figs["N170"]
figs["P3"]
 =#


figs2 = Dict{String,Figure}()
for cfg in configs_tasks3
    n_cols = 4
    n_rows = cld(length(cfg.subjects), n_cols)

    fig = Figure(size = (1600, 320 + 360 * n_rows), figure_padding = (10, 10, 24, 24))
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, 12)
    rowgap!(gl, 18)

    k = 0
    for subj in cfg.subjects
        test = load_erp_subject_or_nothing(
            cfg.task;
            subject = subj,
            timepoint = cfg.timepoint,
            condition = cfg.condition,
        )
        isnothing(test) && continue

        k += 1
        i = cld(k, n_cols)
        j = mod1(k, n_cols)

        plot_topoplot!(
            gl[i, j],
            test.estimate;
            labels = test.labels,
            axis = (; xlabel = "", title = "$(cfg.task)_$(subj)", titlesize = 28),
            colorbar = (; label = "", vertical = false, position = :bottom, width = 180),
            visual = (;
                colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
                contours = true,
            ),
        )
    end

    figs2[cfg.task] = fig
    # save("$(cfg.task)_selected_region_topoplots.png", fig)
end

figs2["MMN"]
figs2["N170"]
figs2["P3"]


g

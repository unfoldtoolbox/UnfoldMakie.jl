include("../usable/region_detection_helpers.jl")
include("../usable/stimuli_data.jl")

test = load_erp_subject("MMN"; subject=20, timepoint=96, condition=1)
test = load_erp_subject("N2pc"; subject=1, timepoint=96, condition=1)

t = abs.(test.estimate) ./ test.se
f = plot_topoplot(
            test.abs_t;
            #test.estimate ./ test.se;
            #t;
            labels = test.labels,
            axis = (; xlabel = ""),
            visual = (; contours=true, colormap=cgrad(:RdYlBu, 10; categorical=true, rev = true)),
            colorbar = (; labelsize=24, ticklabelsize=18, height=350, label = "SNR"#"|estiamte|/se"#
            ),
        )

positions = TopoPlots.labels2positions(test.labels)

begin
    f = plot_topoplot(
        test.abs_t;
        labels = test.labels,
        axis = (; xlabel = ""),
        visual = (; contours=true, colormap=cgrad(:RdYlBu, 10; categorical=true, rev=true)),
        colorbar = (; labelsize=24, ticklabelsize=18, height=350, label = "SNR"),
    )
    ax = f.content[2]
    overlay_region_polygons!(
        ax,
        TOPO_REGIONS;
        head_center=(0f0, -0.08f0),
        head_radius=1.33,
        template_center=(150.0, 150.0),
        template_radius=150.0,
        fontsize=20,
    )
    f
end

# target topoplot for illustration
begin 
    test = load_erp_subject("N2pc"; subject = 1, timepoint = 96, condition = 1)
    f = Figure()
    ax = Axis(f[1, 1])
    ax.title = "Target topoplot"
    ax.titlesize = 26
    hidedecorations!(ax) ; hidespines!(ax)
     plot_topoplot!(f, test.estimate ./ test.se; labels = test.labels, axis = (; xlabel = ""), 
        colorbar = (; labelsize = 24, ticklabelsize = 18),)
    save("stimuli/SNR0.png", f)
end

# voltafm noise and SNR plots for illustration
begin
    test = load_erp_subject("N2pc"; subject = 3, timepoint = 80, condition = 2)
    f = triple_SNR(test; sew = 2)
    save("stimuli/triple_SNR.png", f)
end

## Idea: we need to find xg, yg, data_interpolated and mask
# not always at the same place

# base
fig = Figure()
ax = Axis(fig[1,1])
h = eeg_topoplot!(ax, test.abs_t; labels=test.labels)
fig

# good for search
typeof(h)
propertynames(h)
fieldnames(typeof(h))
dump(h; maxdepth=2)



tp = h.plots[1]
xg = tp.xg[]
yg = tp.yg[]
Z  = tp.data_interpolated[]
M  = tp.mask[]
Zmask = M .* Z

#typeof(xg), size(Z), typeof(M)
#minimum(Z), maximum(Z)


heatmap(xg, yg, Z)
heatmap(xg, yg, Zmask)


# creating heatmap from xg, yg, Z 
begin
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel = "", aspect = DataAspect(),)

    hm = heatmap!(
        ax,
        xg, yg, Z;
        colormap = cgrad(:RdYlBu, 10; categorical=true, rev=true),
    )
    fig
end

# single plot, 1-8 scores, no legend
begin
    test = load_erp_subject("N2pc"; subject = 1, timepoint = 96, condition = 1)

    # hidden helper plot only to extract interpolated grid
    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, test.estimate ./ test.se; labels = test.labels)

    tp = h.plots[1]
    xg = tp.xg[]
    yg = tp.yg[]
    Z  = tp.data_interpolated[]
    M  = tp.mask[]
    Zmask = M .* abs.(Z)

    rows_t = region_weights_from_grid(
        xg, yg, Zmask, TOPO_REGIONS;
        agg = :mean,
        n_bins = 8,
        binning = :quantile,
    )

    weights = Dict(r.label => r.weight for r in rows_t)

    palette8 = Dict(
        i => cgrad(:RdYlBu, 8; categorical = true, rev = true)[i]
        for i in 1:8
    )

    f, ax = plot_region_weight_topoplot(
        weights;
        show_labels = true,
        template_radius = 126.0f0,
        region_center = (0f0, 0.08f0),
        fontsize = 22,
        fontcolor = :black,
        palette = palette8,
    )

    ax.title = "N2pc | subject 1 | 96 ms | condition 1"
    ax.titlesize = 20

  
    f
end


# single plot, 1-8 scores, with legend
begin
    test = load_erp_subject("N2pc"; subject = 1, timepoint = 96, condition = 1)

    tmpfig = Figure()
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, test.estimate ./ test.se; labels = test.labels)

    tp = h.plots[1]
    xg = tp.xg[]
    yg = tp.yg[]
    Z  = tp.data_interpolated[]
    M  = tp.mask[]
    Zmask = M .* abs.(Z)

    rows_t = region_weights_from_grid(
        xg, yg, Zmask, TOPO_REGIONS;
        agg = :mean,
        n_bins = 8,
        binning = :quantile,
    )

    weights = Dict(r.label => r.weight for r in rows_t)

    palette8 = Dict(
        i => cgrad(:RdYlBu, 8; categorical = true, rev = true)[i]
        for i in 1:8
    )

    f, ax = plot_region_weight_topoplot(
        weights;
        show_labels = true,
        template_radius = 126.0f0,
        region_center = (0f0, 0.08f0),
        fontsize = 26,
        fontcolor = :black,
        palette = palette8,
    )

    ax.title = "Example SNR topoplot with 32 regions"
    ax.titlesize = 26

    legax = Axis(
        f[2, 1],
        title = "Region weights",
        titlesize = 26,
    )

    hidedecorations!(legax)
    hidespines!(legax)
    limits!(legax, 0, 8.2, 0, 1)

    xs = range(0.5, 7.5; length = 8)

    for (x, w) in zip(xs, 1:8)
        poly!(
            legax,
            Point2f[
                (x - 0.18, 0.38),
                (x + 0.18, 0.38),
                (x + 0.18, 0.65),
                (x - 0.18, 0.65),
            ];
            color = palette8[w],
            strokecolor = :black,
            strokewidth = 1,
        )

        text!(
            legax,
            x, 0.23;
            text = string(w),
            align = (:center, :center),
            fontsize = 26,
            color = :black,
        )
    end

    text!(legax, 0.5, 0.86; text = "low", align = (:center, :center), fontsize = 26)
    text!(legax, 7.5, 0.86; text = "high", align = (:center, :center), fontsize = 26)

    rowgap!(f.layout, 2)
    rowsize!(f.layout, 2, Auto(0.16))

    f
 #save("stimuli/SNR.png", f)
end


# ranking regions
ranking = rank_regions(
    positions,
    test.abs_t,
    TOPO_REGIONS;
    head_center=(0f0, -0.08f0),
    head_radius=1.33f0,
    template_center=(150.0f0, 150.0f0),
    template_radius=150.0f0,
    samples=45,
    agg=:mean,       # or :max
)

top4 = ranking[1:4]
println(top4)

# showing weights of regions
weights = region_weights(
    positions,
    test.abs_t,
    TOPO_REGIONS;
    agg=:mean,
    binning=:equal_width,   # or :quantile
    n_bins=4,
    head_center=(0f0, -0.08f0),
    head_radius=1.33f0,
    template_center=(150.0f0, 150.0f0),
    template_radius=150.0f0,
)

# single plot, 1-4 scores, no legend
begin
    rows_t = region_weights_from_grid(xg, yg, abs.(Zmask), TOPO_REGIONS; agg=:mean, binning=:equal_width)
    weights = Dict(r.label => r.weight for r in rows_t)
    f, ax = plot_region_weight_topoplot(weights; show_labels=true, 
    template_radius=126.0f0, region_center=(0f0, 0.08f0), fontsize = 24, fontcolor = :red)
    f
end

# single plot, 1-4 scores, with legend
begin
    h = eeg_topoplot!(ax, test.estimate ./ test.se; labels=test.labels)
    tp = h.plots[1]
    xg = tp.xg[]
    yg = tp.yg[]
    Z  = tp.data_interpolated[]
    M  = tp.mask[]
    Zmask = M .* Z
    rows_t = region_weights_from_grid(xg, yg, Zmask, TOPO_REGIONS; agg = :mean, n_bins = 4, binning = :quantile)
    weights = Dict(r.label => r.weight for r in rows_t)
    palette = Dict(
        1 => :gray90,
        2 => :skyblue1,
        3 => :deepskyblue3,
        4 => :navy,
    )

    f, ax = plot_region_weight_topoplot(
        weights;
        show_labels = true,
        template_radius = 126.0f0,
        region_center = (0f0, 0.08f0),
        fontsize = 24,
        fontcolor = :red,
        palette = palette,
    )

    legax = Axis(f[2, 1], title = "Configs: agg = :mean, binning = :quantile")
    hidedecorations!(legax); hidespines!(legax)
    limits!(legax, 0, 5.2, 0, 1)

    cols = [palette[1], palette[2], palette[3], palette[4]]
    labs = ["1 = lowest", "2", "3", "4 = highest"]
    xs = [0.6, 1.8, 3.0, 4.2]

    for (x, c, lab) in zip(xs, cols, labs)
        poly!(legax,
            Point2f[(x-0.18, 0.35), (x+0.18, 0.35), (x+0.18, 0.65), (x-0.18, 0.65)];
            color = c,
            strokecolor = :black,
        )
        text!(legax, x + 0.28, 0.5;
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
    (task = "MMN",  subjects = [20, 25, 26], timepoint = 96,  condition = 3, shift = 0.0),
    (task = "P3",   subjects = [11, 12, 16], timepoint = 128, condition = 1, shift = 4.55),
    (task = "N170", subjects = [26, 5, 12],  timepoint = 105, condition = 2, shift = 0.0),
]

rks = make_region_key(configs_tasks; n_bins=4, agg = :mean, binning = :quantile)
rks8 = make_region_key(configs_tasks; n_bins=8, agg = :mean, binning = :quantile)

# 9 region topopltos with 1-4 scores
begin
    fig = Figure(size=(800, 800))
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, 12)
    rowgap!(gl, 18)

    for (k, row) in enumerate(rks)
        i = cld(k, 3)
        j = mod1(k, 3)

        ax = Axis(gl[i, j], aspect=DataAspect(), title=row.stimulus, titlesize=20)
        hidedecorations!(ax)
        hidespines!(ax)

        plot_region_weight_topoplot!(
            ax,
            row.weights;
            show_labels=true,
            template_radius=126.0f0,
            region_center=(0f0, 0.08f0),
            fontsize=18,
            fontcolor=:red,
        )
    end

    fig
end

# 9 region topopltos with 1-8 scores. Preferred
begin
    fig = Figure(size=(800, 800))
    gl = fig[1, 1] = GridLayout()
    colgap!(gl, 12)
    rowgap!(gl, 18)
    palette8 = Dict(i => cgrad(:RdYlBu, 8; categorical=true, rev=true)[i] for i in 1:8)
    for (k, row) in enumerate(rks8)
        i = cld(k, 3)
        j = mod1(k, 3)

        ax = Axis(gl[i, j], aspect=DataAspect(), title=row.stimulus, titlesize=20)
        hidedecorations!(ax)
        hidespines!(ax)

        plot_region_weight_topoplot!(
            ax,
            row.weights;
            show_labels=true,
            template_radius=126.0f0,
            region_center=(0f0, 0.08f0),
            fontsize=18,
            palette = palette8,
            fontcolor=:black,
        )
    end

    fig
end

configs_tasks = [
    (task = "MMN",  subjects = [20, 25, 26], timepoint = 96,  condition = 3, shift = 0.0),
    (task = "P3",   subjects = [11, 12, 16], timepoint = 128, condition = 1, shift = 4.55),
    (task = "N170", subjects = [26, 5, 12],  timepoint = 105, condition = 2, shift = 0.0),
]



tests = [
    ("MMN_20",  load_erp_subject("MMN";  subject=20, timepoint=96,  condition=3)),
    ("MMN_25",  load_erp_subject("MMN";  subject=25, timepoint=96,  condition=3)),
    ("MMN_26",  load_erp_subject("MMN";  subject=26, timepoint=96,  condition=3)),
    ("P3_11",   load_erp_subject("P3";   subject=11, timepoint=128, condition=1)),
    ("P3_12",   load_erp_subject("P3";   subject=12, timepoint=128, condition=1)),
    ("P3_16",   load_erp_subject("P3";   subject=16, timepoint=128, condition=1)),
    ("N170_26", load_erp_subject("N170"; subject=26, timepoint=105, condition=2)),
    ("N170_5",  load_erp_subject("N170"; subject=5,  timepoint=105, condition=2)),
    ("N170_12", load_erp_subject("N170"; subject=12, timepoint=105, condition=2)),
]


# 9 topoplots for illustration
begin
    f = Figure(size = (1100, 1100))

    for (k, (stim, test)) in enumerate(tests)
        r = div(k - 1, 3) + 1
        c = mod(k - 1, 3) + 1

        tvals = test.estimate ./ test.se

        plot_topoplot!(
            f[r, c],
            tvals;
            labels = test.labels,
            axis = (; xlabel = "", title = stim),
            colorbar = (; vertical = false, position = :bottom, width = 180),
            visual = (; colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
                    contours = true),
        )
    end

    f
end

test = load_erp_subject("MMN"; subject=20, timepoint=96, condition=1)
f = plot_topoplot(
            test.abs_t;
            labels = test.labels,
            axis = (; xlabel = ""),
            visual = (; contours=true, colormap=cgrad(:RdYlBu, 10; categorical=true, rev = true)),
            colorbar = (; labelsize=24, ticklabelsize=18, height=350),
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

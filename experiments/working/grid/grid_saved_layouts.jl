# Helpers that rebuild working layouts from saved `regions.jl` exports.

# Rebuild a plot-ready layout from a saved region export on the canonical head domain.
function layout_from_saved_regions(
    regions,
    cfg::RegionGrid64Config;
    name = :loaded,
    title = "Loaded region grid",
)
    labels, _ = UnfoldMakie.example_montage("montage_64")
    tmpfig = Figure(size = (10, 10))
    tmpax = Axis(tmpfig[1, 1])
    h = eeg_topoplot!(tmpax, zeros(Float32, length(labels)); labels = labels, contours = false, clip = false)

    canonical_domain = region_head_domain_from_plot(h)
    display_domain = topoplot_domain_from_plot(h, cfg)
    fitted = fit_region_polygons_to_domain(
        regions,
        canonical_domain;
        template_center = cfg.template_center,
        template_radius = cfg.template_radius,
        head_center = cfg.parser_head_center,
        head_radius = cfg.parser_head_radius,
    )
    cells = fitted.polygons
    metrics = build_metrics(cells)
    loaded_regions = [
        (
            label = region.label,
            points = region.points,
            polygon = cells[idx],
            center = metrics.centroids[idx],
            template_center = Point2f(0, 0),
            area = metrics.areas[idx],
            compactness = metrics.compactness[idx],
        ) for (idx, region) in enumerate(regions)
    ]

    return RegionLayout64(
        name = name,
        title = title,
        domain = display_domain,
        seeds = Point2f[],
        weights = Float64[],
        cells = cells,
        metrics = metrics,
        regions = loaded_regions,
    )
end

# Return the default config used for the saved EEG-aligned 64-region export.
function saved_eeg_aligned_config()
    RegionGrid64Config(
        output_dir = joinpath(dirname(dirname(@__DIR__)), "figures", "task2_topo_regions_64_eeg_aligned"),
        basename = "task2_topo_regions_64_eeg_aligned",
        region_const_name = "TOPO_REGIONS_64_EEG_ALIGNED",
    )
end

# Load the saved EEG-aligned region export without rebuilding the optimizer.
function load_saved_eeg_aligned_regions()
    filepath = joinpath(saved_eeg_aligned_config().output_dir, "regions.jl")
    scratch = Module(gensym(:SavedEEGAlignedRegions))
    Core.eval(scratch, Meta.parse(read(filepath, String)))
    Core.eval(scratch, :TOPO_REGIONS_64_EEG_ALIGNED)
end

# Rebuild a lightweight layout from the saved EEG-aligned region export.
function load_saved_eeg_aligned_layout()
    cfg = saved_eeg_aligned_config()
    layout_from_saved_regions(
        load_saved_eeg_aligned_regions(),
        cfg;
        name = :eeg_aligned_loaded,
        title = "Loaded EEG-aligned region grid",
    )
end

# Render the pipeline figure from the saved EEG-aligned 64-region export.
function saved_eeg_aligned_pipeline_figure()
    cfg = saved_eeg_aligned_config()
    pipeline_case_figure(load_saved_eeg_aligned_layout(), cfg)
end

# Return the saved config for one EEG-aligned count-search run.
function saved_count_search_run_config(
    region_count::Int;
    base_output_dir = joinpath(
        dirname(dirname(@__DIR__)),
        "figures",
        "task2_topo_regions_eeg_aligned_count_search_pipeline28",
    ),
)
    RegionGrid64Config(
        output_dir = joinpath(base_output_dir, @sprintf("N%02d", region_count)),
        basename = @sprintf("task2_topo_regions_N%02d_eeg_aligned", region_count),
        region_const_name = @sprintf("TOPO_REGIONS_%02d_EEG_ALIGNED", region_count),
        php_function_name = @sprintf("topo_polygons_%d", region_count),
        digits = 3,
    )
end

# Load one saved EEG-aligned count-search region export without rebuilding the search.
function load_saved_count_search_regions(
    region_count::Int;
    base_output_dir = joinpath(
        dirname(dirname(@__DIR__)),
        "figures",
        "task2_topo_regions_eeg_aligned_count_search_pipeline28",
    ),
)
    cfg = saved_count_search_run_config(region_count; base_output_dir = base_output_dir)
    filepath = joinpath(cfg.output_dir, "regions.jl")
    scratch = Module(gensym(:SavedCountSearchRegions))
    Core.eval(scratch, Meta.parse(read(filepath, String)))
    Core.eval(scratch, Symbol(cfg.region_const_name))
end

# Rebuild a lightweight layout from one saved EEG-aligned count-search run.
function load_saved_count_search_layout(
    region_count::Int;
    base_output_dir = joinpath(
        dirname(dirname(@__DIR__)),
        "figures",
        "task2_topo_regions_eeg_aligned_count_search_pipeline28",
    ),
)
    cfg = saved_count_search_run_config(region_count; base_output_dir = base_output_dir)
    layout_from_saved_regions(
        load_saved_count_search_regions(region_count; base_output_dir = base_output_dir),
        cfg;
        name = Symbol(@sprintf("count_search_N%02d", region_count)),
        title = @sprintf("Loaded EEG-aligned count-search N=%d grid", region_count),
    )
end

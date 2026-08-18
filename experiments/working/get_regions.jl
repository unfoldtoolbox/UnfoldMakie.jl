
include("stimuli_data.jl")
include("region_detection/region_score_exports.jl")
include("grid/region_grid64_config.jl")

# Legacy 30-case output with the original region set from `geometry.jl`.
region_scores_30 = make_region_score(task_configs_30_balanced; agg = :mean)
rk = region_score_dict(region_scores_30)
txt = format_region_score(region_scores_30)


# Load one saved `const TOPO_REGIONS_* = [...]` block without polluting `Main`.
function _get_regions_load_saved_const(filepath, const_name::Symbol)
    scratch = Module(gensym(:GetRegionsSavedConst))
    Core.eval(scratch, Meta.parse(read(filepath, String)))
    Core.eval(scratch, const_name)
end

# New-grid output: reuse the saved 64-region EEG-aligned pipeline28 export.
cfg_64_eeg_pipeline28 = RegionGrid64Config(
    output_dir = joinpath("experiments", "figures", "task2_topo_regions_64_eeg_aligned_pipeline28"),
    basename = "task2_topo_regions_64_eeg_aligned_pipeline28",
    region_const_name = "TOPO_REGIONS_64_EEG_ALIGNED_PIPELINE28",
)
regions_64_eeg_pipeline28 = _get_regions_load_saved_const(
    joinpath(cfg_64_eeg_pipeline28.output_dir, "regions.jl"),
    :TOPO_REGIONS_64_EEG_ALIGNED_PIPELINE28,
)
length(regions_64_eeg_pipeline28) == 64 ||
    error("Expected 64 regions in task2_topo_regions_64_eeg_aligned_pipeline28, got $(length(regions_64_eeg_pipeline28)).")
length(unique(String(region.label) for region in regions_64_eeg_pipeline28)) == 64 ||
    error("Expected 64 unique region labels in task2_topo_regions_64_eeg_aligned_pipeline28.")

# Score against the same canonical parser geometry that the saved `regions.jl`
# export and the 64-grid pipeline panel use.
regions_64_eeg_pipeline28_points = [
    (label = region.label, points = region.points) for region in regions_64_eeg_pipeline28
]

# Produce a second PHP payload where every stimulus is scored across all 64 new-grid regions.
region_scores_30_balanced_new_grid = make_region_score(
    task_configs_30_balanced;
    regions = regions_64_eeg_pipeline28_points,
    agg = :mean,
    template_center = cfg_64_eeg_pipeline28.template_center,
    template_radius = cfg_64_eeg_pipeline28.template_radius,
    head_center = cfg_64_eeg_pipeline28.parser_head_center,
    head_radius = cfg_64_eeg_pipeline28.parser_head_radius,
)
all(length(row.scores) == 64 for row in region_scores_30_balanced_new_grid) ||
    error("Expected 64 scored regions per row in region_scores_30_balanced_new_grid.")
rk_new_grid = region_score_dict(region_scores_30_balanced_new_grid)

# Build the same rounded normalized score table that panel 7 in
# `64grid_30_cases_pipeline` displays, then compare it with `txt_new_grid`.
function check_txt_new_grid_matches_64grid_pipeline_panel7(
    configs = task_configs_30_balanced;
    table_rows = region_scores_30_balanced_new_grid,
)
    panel7_rows = make_region_score_panel7(
        configs;
        regions = regions_64_eeg_pipeline28_points,
        agg = :mean,
        template_center = cfg_64_eeg_pipeline28.template_center,
        template_radius = cfg_64_eeg_pipeline28.template_radius,
        head_center = cfg_64_eeg_pipeline28.parser_head_center,
        head_radius = cfg_64_eeg_pipeline28.parser_head_radius,
    )

    (
        panel7_rows = panel7_rows,
        table_rows = table_rows,
        comparison = compare_region_score_rows(panel7_rows, table_rows),
    )
end

txt_new_grid_panel7_check = check_txt_new_grid_matches_64grid_pipeline_panel7()

txt_new_grid = format_region_score(
    region_scores_30_balanced_new_grid;
    fn_name = "region_scores_30_balanced_new_grid",
)
txt_new_grid_value_arrays = format_region_score_value_arrays(
    region_scores_30_balanced_new_grid;
    fn_name = "region_scores_30_balanced_new_grid_values",
)

println(txt_new_grid)
println(txt_new_grid_value_arrays)
println(format_region_score_comparison(txt_new_grid_panel7_check.comparison))

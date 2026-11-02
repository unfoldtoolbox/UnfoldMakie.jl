@isdefined(build_task2_region_grid64) || include(joinpath(@__DIR__, "grid_partition.jl"))

include(joinpath(@__DIR__, "grid_alignment.jl"))
include(joinpath(@__DIR__, "grid_pipeline_plots.jl"))
include(joinpath(@__DIR__, "grid_outline_plots.jl"))
include(joinpath(@__DIR__, "grid_saved_layouts.jl"))

function generate_task2_region_grid64(; kwargs...)
    result = build_task2_region_grid64(; kwargs...)
    return (; config = result.config, layouts = result.layouts)
end

const _TASK2_REGION_GRID64_CACHE = Ref{Any}(nothing)

# Lazy getter: build the default 64-grid only when some caller actually asks
# for it, instead of doing that work while `grid_views.jl` is being included.
function task2_region_grid64(; force_rebuild = false, kwargs...)
    if !force_rebuild && isempty(kwargs)
        cached = _TASK2_REGION_GRID64_CACHE[]
        isnothing(cached) || return cached
        cached = generate_task2_region_grid64()
        _TASK2_REGION_GRID64_CACHE[] = cached
        return cached
    end

    result = generate_task2_region_grid64(; kwargs...)
    isempty(kwargs) && (_TASK2_REGION_GRID64_CACHE[] = result)
    return result
end

# One-stop helper for the saved EEG-aligned count-search workflow that gets
# aligned to the montage used by the topoplot figures and SoSci exports.
function count_search_montage28_bundle(
    region_count::Int;
    base_output_dir = joinpath(
        dirname(dirname(@__DIR__)),
        "figures",
        "task2_topo_regions_eeg_aligned_count_search_pipeline28",
    ),
    target_dir = joinpath("experiments", "target stimuli"),
    stem = "task2_region_grid$(region_count)",
)
    layout = load_saved_count_search_layout(region_count; base_output_dir = base_output_dir)
    cfg = saved_count_search_run_config(region_count; base_output_dir = base_output_dir)
    avgref = load_grid_avgref_case_or_nothing(cfg)
    isnothing(avgref) && error(
        "Missing avgref data for montage28 bundle: task=$(cfg.pipeline_task), subject=$(cfg.pipeline_subject), " *
        "timepoint=$(cfg.pipeline_timepoint), condition=$(cfg.pipeline_condition).",
    )

    aligned_layout = display_aligned_layout(
        layout,
        cfg;
        alignment_labels = avgref.labels,
    )

    fig_outline = clean_partition_outline_figure(layout, cfg)
    path_outline = save_clean_partition_outline(
        layout,
        cfg;
        filepath = joinpath(target_dir, "$(stem).png"),
    )

    fig_montage28_outline = clean_partition_outline_figure(
        layout,
        cfg;
        electrode_labels = avgref.labels,
        alignment_labels = avgref.labels,
    )
    path_montage28_outline = save_clean_partition_outline(
        layout,
        cfg;
        filepath = joinpath(target_dir, "$(stem)_montage28_preview.png"),
        electrode_labels = avgref.labels,
        alignment_labels = avgref.labels,
    )

    path_svg = let
        p = joinpath(target_dir, "$(stem)_montage28.svg")
        mkpath(dirname(p))
        write(p, socsi_svg_text(aligned_layout, cfg) * "\n")
        p
    end

    path_php = let
        p = joinpath(target_dir, "$(stem)_montage28.php")
        mkpath(dirname(p))
        write(p, php_svg_function_text(aligned_layout, cfg) * "\n")
        p
    end

    fig_sosci_overlay = montage28_sosci_overlay_figure(
        layout,
        cfg;
        alignment_labels = avgref.labels,
        selectable_layout = aligned_layout,
        electrode_labels = avgref.labels,
    )
    path_sosci_overlay = save_montage28_sosci_overlay(
        layout,
        cfg;
        filepath = joinpath(target_dir, "$(stem)_montage28_sosci_overlay.png"),
        alignment_labels = avgref.labels,
        selectable_layout = aligned_layout,
        electrode_labels = avgref.labels,
    )

    return (
        ;
        layout,
        cfg,
        avgref,
        aligned_layout,
        fig_outline,
        path_outline,
        fig_montage28_outline,
        path_montage28_outline,
        path_svg,
        path_php,
        fig_sosci_overlay,
        path_sosci_overlay,
    )
end

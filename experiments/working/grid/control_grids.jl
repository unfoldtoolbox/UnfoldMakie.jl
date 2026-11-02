include(joinpath(@__DIR__, "grid_views.jl"))

# This file is a "control sheet" for the grid debugging workflow.
# Each top-level variable below runs one ready-made example and keeps the
# result in memory so you can inspect it in the REPL.
#
# Roughly:
# - `fig_*` variables create Makie figures for visual inspection
# - `path_*` variables save files to disk and return the saved path
# - `.svg` / `.php` outputs are the selectable polygon exports for SoSci
# - `*_preview.*` outputs are rendered preview images for humans

# 1. The default 64-region pipeline example (outdated)
# This shows the step-by-step "panel" figure for the built-in 64-region grid.
fig_64 = let
    grid64 = task2_region_grid64()
    pipeline_case_figure(grid64.layouts.final, grid64.config)
end

# 2. The same pipeline idea, but using the saved EEG-aligned 64-region grid
# instead of the default synthetic one.
fig_64_eeg_aligned = saved_eeg_aligned_pipeline_figure()

# 3. Run the whole saved N=64 -> montage28 -> SoSci export cookbook in one call.
count_search_64 = count_search_montage28_bundle(64)

# 4. Keep the most useful outputs under explicit variable names for quick REPL
# inspection and for copy/paste into other debug snippets.
# Base objects for this saved N=64 run:
# - `layout_64_count_search` = the loaded region polygons on their saved head domain
# - `cfg_64_count_search` = export/alignment settings used with that layout
# - `grid_avgref_64_count_search` = the avgref ERP case that provides the montage labels
# - `layout_64_count_search_montage28` = the same polygons moved onto the montage28 display domain
layout_64_count_search = count_search_64.layout
cfg_64_count_search = count_search_64.cfg
grid_avgref_64_count_search = count_search_64.avgref
layout_64_count_search_montage28 = count_search_64.aligned_layout

# Pair 1: clean outline preview.
# - `fig_*` is the in-memory Makie figure for visual inspection in the REPL
# - `path_*` is the saved PNG on disk
# Use this pair when you only want to check border geometry, without montage alignment.
fig_64_count_search_outline = count_search_64.fig_outline
path_64_count_search_outline = count_search_64.path_outline

# Pair 2: montage28-aligned preview with electrode dots.
# - `fig_*` is the inspection figure
# - `path_*` is the saved preview PNG
# Use this pair when you want to compare the grid against the same electrode montage
# that appears in the EEG/topoplot-based figures.
fig_64_count_search_outline_montage28 = count_search_64.fig_montage28_outline
path_64_count_search_outline_montage28 = count_search_64.path_montage28_outline

# Pair 3: canonical selectable geometry for the survey platform.
# - `.svg` is the raw selectable polygon export
# - `.php` wraps the same polygon export in a PHP function
# Use these when the survey should receive clickable regions.
path_64_count_search_outline_montage28_svg = count_search_64.path_svg
path_64_count_search_outline_montage28_php = count_search_64.path_php

# Pair 4: overlay diagnostic.
# - `fig_*` overlays the montage28 preview and the selectable polygons in memory
# - `path_*` saves the same diagnostic as a PNG
# Use this pair when you need to confirm that the SoSci geometry still sits
# exactly on top of the montage-aligned preview.
fig_64_count_search_outline_montage28_sosci_overlay = count_search_64.fig_sosci_overlay
path_64_count_search_outline_montage28_sosci_overlay = count_search_64.path_sosci_overlay

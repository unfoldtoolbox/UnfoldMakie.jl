# Working Grid README

This folder contains the working-side copy of the grid debugging stack.

It was copied from `experiments/playground/grid` and then pruned so it keeps
only the pieces needed by `control_grids.jl`.

## Files In This Folder

- `control_grids.jl`
  Top-level control sheet for the REPL. Running this file creates the ready-made
  figures and saved files used to inspect the 64-region grid workflow.

- `grid_views.jl`
  Thin loader file. It includes the four focused helper files below and keeps
  the public entrypoints stable for `control_grids.jl`.

- `grid_alignment.jl`
  Alignment helpers used to move saved/selectable polygons onto the same head
  domain as Makie topoplots. This file also contains the avgref-label loader
  used for montage alignment.

- `grid_pipeline_plots.jl`
  Pipeline figure helpers. It contains:
  - panel builders for the 64-grid pipeline figure
  - the shared region-score payload used by the figure and score checks
  - head-outline drawing helpers used inside pipeline-style panels

- `grid_outline_plots.jl`
  Human-facing outline previews and overlay checks. It contains:
  - clean outline rendering
  - outline save helpers
  - montage28 vs SoSci overlay diagnostics

- `grid_saved_layouts.jl`
  Saved-layout loaders. It contains:
  - rebuilding `RegionLayout64` from exported `regions.jl` files
  - helpers for the saved EEG-aligned grid
  - helpers for saved count-search runs

- `grid_partition.jl`
  Thin loader for the four low-level grid source files below. It keeps the old
  include path stable for code that still loads `grid_partition.jl`.

- `grid_types.jl`
  Shared structs:
  - `TopoplotDomain`
  - `RegionLayout64`

- `grid_geometry.jl`
  Geometry helpers:
  - polygon math and cleanup
  - head/domain extraction from topoplots
  - polygon mapping between head domains

- `grid_builder.jl`
  Grid construction helpers:
  - seed generation
  - Voronoi / power-cell optimization
  - metrics and region labeling
  - `build_task2_region_grid64`

- `grid_export.jl`
  Canonical selectable-geometry exports:
  - SVG polygon text
  - SoSci SVG text
  - PHP wrapper text

- `region_grid64_config.jl`
  Shared `RegionGrid64Config` definition. This is the minimal grid-related code
  that is also used by `experiments/working/get_regions.jl`.

## What The Control File Produces

The control file is meant to be read from top to bottom.

- `fig_64`
  Pipeline figure for the default 64-region grid.

- `fig_64_eeg_aligned`
  Pipeline figure for the saved EEG-aligned 64-region grid.

- `fig_64_count_search_outline`
  Clean outline preview of the saved N=64 count-search result.

- `fig_64_count_search_outline_montage28`
  The same outline, but aligned to the montage used by the EEG/topoplot figure.

- `path_64_count_search_outline_montage28_svg`
  Canonical selectable SVG polygons for SoSci.

- `path_64_count_search_outline_montage28_php`
  The same selectable polygons wrapped as a PHP function.

- `fig_64_count_search_outline_montage28_sosci_overlay`
  Overlay diagnostic used to check whether the selectable polygons match the
  montage-aligned preview.

## Preview vs Selectable Exports

There are two different kinds of outputs in this workflow.

- Preview outputs are for humans.
  These are rendered images with head outlines, borders, and sometimes
  electrode markers.

- Selectable exports are for SoSci.
  These are polygon-only `.svg` / `.php` files that define the clickable region
  geometry.

Rule of thumb:

- `*_preview.*` = visual check image
- `.svg` / `.php` without `preview` = canonical selectable region geometry

## Saved Data Dependencies

This folder does not regenerate the full EEG-aligned grid search by itself.
Instead, several helpers load previously saved region exports from:

- `experiments/figures/task2_topo_regions_64_eeg_aligned`
- `experiments/figures/task2_topo_regions_eeg_aligned_count_search_pipeline28`

So if a helper says a saved `regions.jl` file is missing, the corresponding
grid-generation pipeline must be run first.

## Important Geometry Parameters

The most important parameters inside `RegionGrid64Config` are:

- `template_center`, `template_radius`
  Control the 300x300 template coordinate system used for exported polygons.

- `parser_head_center`, `parser_head_radius`
  Define the canonical head space used when parsing and scoring polygons.

- `pipeline_task`, `pipeline_subject`, `pipeline_timepoint`, `pipeline_condition`
  Select the reference ERP case used by the pipeline figure and by montage
  alignment helpers.

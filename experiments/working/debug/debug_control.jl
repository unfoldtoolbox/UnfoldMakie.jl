include("../stimuli_data.jl")
Base.include(
    UnfoldMakie,
    joinpath(dirname(pathof(UnfoldMakie)), "general_plots", "plot_topoplot.jl"),
)

# -----------------------------------------------------------------------------
# 1-2. Topoplots look like targets and diverge over zero
# -----------------------------------------------------------------------------

include("../region_detection/search_stimuli.jl")

save_search_stimuli_pdf(
    task_configs_all;
    filepath = joinpath("experiments", "pdfs_balanced", "all_stimuli_topos.pdf"),
)


save_search_stimuli_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_stimuli_topos.pdf"),
)


# -----------------------------------------------------------------------------
# 3. Rereferencing is correct
# -----------------------------------------------------------------------------

include("debug_rereferencing.jl")

top30_rereferencing_path = rereferencing_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_rereferencing.pdf"),
)

# -----------------------------------------------------------------------------
# 4. SNR shows influence of both SE and signal
# -----------------------------------------------------------------------------

include("debug_sss.jl")
include("debug_sss_peaks.jl")
include("debug_sss_peaks_by_regions.jl")
include("debug_sss_peaks_topo.jl")

top30_sss_path = sss_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_sss.pdf"),
    normalise = false,
    orientation = :portrait,
    rereference_voltage = true,
)

#= top30_sss_peaks_path = sss_peaks_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_sss_peaks.pdf"),
) =#

#= top30_sss_peaks_path = sss_peaks_pdf(
    task_configs_all;
    filepath = joinpath("experiments", "pdfs_balanced", "all_cases_sss_peaks_by_electode.pdf"),
) =#

all_sss_peaks_by_regions_path = sss_peaks_by_regions_pdf(
    task_configs_all;
    filepath = joinpath("experiments", "pdfs_balanced", "all_cases_sss_peaks_by_regions.pdf"),
)

all_sss_peaks_by_regions_path = sss_peaks_by_regions_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_sss_peaks_by_regions.pdf"),
)

grid64_30_cases_sss_peaks_by_regions_path = sss_peaks_by_regions_pdf_64_eeg_grid(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "64grid_30_cases_sss_peaks_by_regions.pdf"),
)

top30_sss_peaks_topo_path = sss_peaks_topo_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_sss_peaks_topo.pdf"),
)

grid64_30_cases_sss_peaks_topo_path = sss_peaks_topo_pdf_64_eeg_grid(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "64grid_30_cases_sss_peaks_topo.pdf"),
)

all_sss_peaks_topo_path = sss_peaks_topo_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "all_cases_sss_peaks_topo.pdf"),
)
# -----------------------------------------------------------------------------
# 5. All individual plots are plotted correctly for all cases
# -----------------------------------------------------------------------------

include("../region_detection/rereferencing.jl")
include("debug_plots.jl")

all_cases_combined_path = combined_pdf(
    task_configs_all;
    filepath = joinpath("experiments", "pdfs_balanced", "all_cases_combined_uncerts.pdf"),
)

top30_combined_path = combined_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_combined_uncerts.pdf"),
)

# -----------------------------------------------------------------------------
# 6. Scores match interpretation
# -----------------------------------------------------------------------------

include("debug_pipeline.jl")

top30_pipeline_path = pipeline_pdf(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "30_cases_pipeline.pdf"),
)

grid64_30_cases_pipeline_path = pipeline_pdf_64_eeg_grid(
    task_configs_30_balanced;
    filepath = joinpath("experiments", "pdfs_balanced", "64grid_30_cases_pipeline.pdf"),
)
# -----------------------------------------------------------------------------
# 7. Illustrations
# -----------------------------------------------------------------------------

# Helper modules used only for the illustration figures in this section:
# - `illustrate_bivariate.jl` builds the step-by-step bivariate pipeline figure
# - `combined_plots.jl` provides the combined uncertainty overview and HOP panel
include("illustrate_bivariate.jl")
include("../plot_fitting/combined_plots.jl")

# A. Static combined-uncertainty example.
# This is the plain combined figure for one case and is useful as the quickest
# visual check before generating heavier assets like GIFs.
fig = combined_case_figure(
    "P3";
    subject = 8,
    timepoint = 129,
    condition = 1,
    title = "",
)
save(joinpath("experiments", "figures", "P3_8_combined_uncerts.png"), fig)

# B. Combined-uncertainty figure with the extra HOP panel included.
# Use this one when you want the still image version of the same setup that is
# later animated in the GIF example below.
fig_hop = combined_case_figure(
    "P3";
    subject = 8,
    timepoint = 129,
    condition = 1,
    title = "",
    include_hop = true,
    figure_size = (1700, 800),
    triple_topo_size = 180,
    triple_colorbar_gap = -50,
)
save(joinpath("experiments", "figures", "P3_8_combined_uncerts_hop.png"), fig_hop)

# C. Animated HOP example for the same case.
# This is the export to inspect how the HOP panel evolves, not just its final
# static appearance.
combined_hop_gif_path = combined_case_hop_gif(
    "P3";
    subject = 8,
    timepoint = 129,
    condition = 1,
    title = "",
    figure_size = (1700, 800),
    triple_topo_size = 180,
    triple_colorbar_gap = -50,
    filepath = joinpath("experiments", "figures", "P3_8_combined_uncerts_hop.gif"),
)


# D. Bivariate pipeline illustration.
# This figure explains how the final bivariate topoplot is assembled from the
# scalar inputs and intermediate scalp-grid representation.
begin
    fig = bivariate_pipeline_case_figure(
        "MMN";
        subject = 1,
        timepoint = 96,
        condition = 3,
    )
    path = joinpath("experiments", "figures", "MMN_1_bivariate_pipeline.png")
    mkpath(dirname(path))
    save(path, fig)
    path
end

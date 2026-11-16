# Panel 7 of the region-scoring pipeline figure ("7. Normalised Scores"):
# mean raw SNR inside each region, rescaled to 0–1.
#
# `plot_region_scoring_pipeline` (pipeline_illustration.jl) draws these values,
# and `get_regions.jl` checks its exported score table against them, so the
# figure and the exported scores are tested against each other.

@isdefined(region_head_domain_from_plot) || include("geometry.jl")
@isdefined(region_weights_from_grid) || include("scoring.jl")
@isdefined(avgref_abs_t) || include("rereferencing.jl")

# Rescale finite values to [0, 1]; non-finite values pass through unchanged.
function pipeline_normalise_zero_one(values)
    vals = Float32[Float32(value) for value in vec(values) if isfinite(value)]
    isempty(vals) && return fill(0f0, size(values))

    lo, hi = extrema(vals)
    hi == lo && return fill(0f0, size(values))

    out = similar(values, Float32)
    for idx in eachindex(values)
        value = values[idx]
        out[idx] = isfinite(value) ? clamp(Float32((value - lo) / (hi - lo)), 0f0, 1f0) : Float32(value)
    end
    out
end

# Panel-7 scores from an existing raw-SNR topoplot `h_score`.
# Returns the per-region rows (label, raw_score, weight) and the 0–1 scores.
function pipeline_panel7_scores(
    h_score,
    regions;
    template_center = (150.0f0, 150.0f0),
    template_radius = 150.0f0,
    head_center = (0.0f0, -0.08f0),
    head_radius = 1.33f0,
)
    tp = h_score.plots[1]
    mask = tp.mask[]
    rows = region_weights_from_grid(
        tp.xg[],
        tp.yg[],
        mask .* tp.data_interpolated[],
        regions;
        agg = :mean,
        template_center = template_center,
        template_radius = template_radius,
        head_center = head_center,
        head_radius = head_radius,
        mask = mask,
        topoplot_domain = region_head_domain_from_plot(h_score),
        n_bins = 8,
        binning = :quantile,
        reverse = false,
    )
    normalised = pipeline_normalise_zero_one(Float64[row.raw_score for row in rows])
    scores = Dict(rows[idx].label => Float64(normalised[idx]) for idx in eachindex(rows))
    (; rows, scores)
end

# Same, starting from one average-referenced subject table.
function pipeline_panel7_scores(subject_data; regions, kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    h_score = eeg_topoplot!(ax, avgref_abs_t(subject_data); labels = subject_data.labels)
    pipeline_panel7_scores(h_score, regions; kwargs...)
end

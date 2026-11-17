# Task 2 (region detection): where participants clicked vs. where the peak was.
#
# Run from the repository root:
#   julia --project=uncertainty_project uncertainty_project/working/task2_results/plot_task2_hits_misses.jl
#
# Inputs (aggregated counts only, written by the analysis repo's
# scripts/export_task2_hits_misses.R):
#   data/task2_results/task2_hits_misses_stimulus.csv  stimulus x vistype x region
#   data/task2_results/task2_hits_misses_regions.csv   pattern x vistype x region
# Geometry: the exact SoSci clickable polygons,
#   target stimuli/task2_region_grid64_montage28.svg (R01..R64 = region_number).
#
# Encoding (all figures):
#   region fill  - ground truth (region score, or share of trials it was the peak)
#   dot area     - share of responses that selected the region
#   orange core  - hits (selected region = peak); grey ring - misses
#   (hit / near hit / miss figures: light orange = near hit, i.e. the selected
#   region shares a border with the peak region)
#
# Outputs: figures/study_results/*.png and *.pdf.

using CairoMakie
using CSV
using DataFrames
using Printf
using Statistics

const T2_ROOT = dirname(dirname(@__DIR__))
const T2_DATA_DIR = joinpath(T2_ROOT, "data", "task2_results")
const T2_FIG_DIR = joinpath(T2_ROOT, "figures", "study_results")
const T2_SVG = joinpath(T2_ROOT, "target stimuli", "task2_region_grid64_montage28.svg")

const T2_PATTERNS = ["MMN", "N170", "P3"]
const T2_VISTYPES = [
    "adjacent", "animation", "bivariate_corner", "bivariate_range",
    "triple_CI", "uncert_markers", "basic",
]
const T2_VISTYPE_LABELS = Dict(
    "all" => "All visualizations",
    "adjacent" => "Adjacent plots",
    "animation" => "Animation",
    "bivariate_corner" => "Bivariate corner",
    "bivariate_range" => "Bivariate range",
    "triple_CI" => "Confidence intervals",
    "uncert_markers" => "Uncertainty markers",
    "basic" => "Basic topoplot",
)

# Colors: one-hue sequential ramp for ground truth, orange for hits,
# dark neutral for misses, text in neutral inks.
const T2_TRUTH_RAMP = cgrad(["#f3f7fc", "#cde2fb", "#9ec5f4", "#6da7ec", "#4b92e8"])
# Ground truth is binned: 5 ticks -> 4 equal bins, lightest bin near-white.
const T2_TRUTH_NBINS = 4
const T2_TRUTH_BINS = [get(T2_TRUTH_RAMP, t) for t in range(0, 1; length = T2_TRUTH_NBINS)]
const T2_TRUTH_CMAP = cgrad(T2_TRUTH_BINS, T2_TRUTH_NBINS; categorical = true)

# Colour for a value already normalised to 0..1 (top edge falls in the last bin).
t2_truth_color(x) = T2_TRUTH_BINS[clamp(floor(Int, x * T2_TRUTH_NBINS) + 1, 1, T2_TRUTH_NBINS)]
const T2_HIT = colorant"#eb6834"
const T2_MISS = colorant"#3d3c3a"
const T2_INK = colorant"#0b0b0b"
const T2_INK2 = colorant"#52514e"
const T2_PEAK_STROKE = colorant"#eb6834"
# Near hit = selected region borders the peak. Lighter step of the hit hue so
# hit > near hit > miss reads as an ordered scale (lightness carries it).
const T2_NEAR = colorant"#f7b996"

# Font sizes chosen for the final display size (Wilke ch. 24): the figures are
# shown ~1100 px wide on the analysis site, so text stays >= ~11 px there.
# Figures carry no in-figure title (Wilke ch. 22): the caption is the title.
const T2_FS = (col = 15, subtitle = 13, row = 18, legend_title = 14, legend = 14, tick = 13)

# Two-line column titles so long visualization names fit a panel width.
const T2_VISTYPE_LABELS2 = Dict(
    "all" => "All\nvisualizations", "adjacent" => "Adjacent\nplots", "animation" => "Animation\n ",
    "bivariate_corner" => "Bivariate\ncorner", "bivariate_range" => "Bivariate\nrange",
    "triple_CI" => "Confidence\nintervals", "uncert_markers" => "Uncertainty\nmarkers",
    "basic" => "Basic\ntopoplot",
)

# Dot diameter in template units (head is 300 units across) for share = 1.
const T2_DOT_SCALE = 68.0

# ---------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------

function t2_load_regions(path = T2_SVG)
    svg = read(path, String)
    rx = r"<polygon points=\"([^\"]+)\" data-region=\"R(\d+)\""
    regions = Dict{Int,Vector{Point2f}}()
    for m in eachmatch(rx, svg)
        pts = Point2f[]
        for pair in split(strip(m.captures[1]))
            x, y = parse.(Float32, split(pair, ","))
            push!(pts, Point2f(x, 300f0 - y))  # SVG y points down
        end
        regions[parse(Int, m.captures[2])] = pts
    end
    sort(collect(keys(regions))) == 1:64 ||
        error("Expected regions R01..R64 in $path, found $(length(regions)).")
    polys = [regions[k] for k in 1:64]
    (; polys, centroids = t2_centroid.(polys), head = t2_head(polys), adj = t2_adjacency(polys))
end

# Neighbours = regions sharing a border (>= 2 common vertices). The SVG cells
# are a partition with identical shared vertices, so exact matching works;
# cells that touch only at a single corner are not neighbours.
function t2_adjacency(polys)
    sets = [Set(p) for p in polys]
    adj = [Int[] for _ in polys]
    for i in eachindex(polys), j in (i + 1):lastindex(polys)
        if length(intersect(sets[i], sets[j])) >= 2
            push!(adj[i], j); push!(adj[j], i)
        end
    end
    any(isempty, adj) && error("Region without neighbours: check polygon geometry.")
    adj
end

function t2_centroid(poly)
    a = 0.0; cx = 0.0; cy = 0.0
    n = length(poly)
    for i in 1:n
        p, q = poly[i], poly[mod1(i + 1, n)]
        c = p[1] * q[2] - q[1] * p[2]
        a += c
        cx += (p[1] + q[1]) * c
        cy += (p[2] + q[2]) * c
    end
    a /= 2
    Point2f(cx / (6a), cy / (6a))
end

function t2_head(polys)
    pts = reduce(vcat, polys)
    xs = first.(pts); ys = last.(pts)
    center = Point2f((minimum(xs) + maximum(xs)) / 2, (minimum(ys) + maximum(ys)) / 2)
    radius = max(maximum(xs) - minimum(xs), maximum(ys) - minimum(ys)) / 2
    (; center, radius)
end

function t2_draw_head!(ax, head)
    c, r = head.center, head.radius
    θ = range(0, 2π; length = 200)
    lines!(ax, c[1] .+ r .* cos.(θ), c[2] .+ r .* sin.(θ); color = T2_INK2, linewidth = 0.8)
    nose = [Point2f(c[1] - 0.10r, c[2] + 0.995r), Point2f(c[1], c[2] + 1.10r),
            Point2f(c[1] + 0.10r, c[2] + 0.995r)]
    lines!(ax, nose; color = T2_INK2, linewidth = 0.8)
end

# ---------------------------------------------------------------------------
# One topoplot panel
# ---------------------------------------------------------------------------

"""
    t2_panel!(ax, geo; fill, colorrange, prop_selected, prop_hits, peaks)

`fill`, `prop_selected`, `prop_hits` are length-64 vectors indexed by region
number; `peaks` lists region numbers to outline as the correct answer.
"""
function t2_panel!(ax, geo; fill, colorrange, prop_selected, prop_hits, peaks = Int[])
    hidedecorations!(ax); hidespines!(ax)
    ax.aspect = DataAspect()
    ax.backgroundcolor = :transparent  # lets a highlight Box behind the panel show
    c, r = geo.head.center, geo.head.radius
    limits!(ax, c[1] - 1.04r, c[1] + 1.04r, c[2] - 1.04r, c[2] + 1.13r)

    for k in 1:64
        poly!(ax, geo.polys[k];
            color = t2_truth_color((fill[k] - colorrange[1]) / (colorrange[2] - colorrange[1])),
            strokecolor = :white, strokewidth = 0.6)
    end
    for k in peaks
        poly!(ax, geo.polys[k]; color = :transparent, strokecolor = T2_PEAK_STROKE, strokewidth = 2.2)
    end
    t2_draw_head!(ax, geo.head)

    sel = findall(>(0), prop_selected)
    isempty(sel) || scatter!(ax, geo.centroids[sel];
        markersize = T2_DOT_SCALE .* sqrt.(prop_selected[sel]), markerspace = :data,
        color = T2_MISS, strokecolor = :white, strokewidth = 0.7)
    hit = findall(>(0), prop_hits)
    isempty(hit) || scatter!(ax, geo.centroids[hit];
        markersize = T2_DOT_SCALE .* sqrt.(prop_hits[hit]), markerspace = :data,
        color = T2_HIT, strokecolor = :white, strokewidth = 0.7)
    ax
end

t2_vec(df, col) = (v = zeros(Float64, 64); v[df.region_number] .= Float64.(df[!, col]); v)

# ---------------------------------------------------------------------------
# "Most correct" / "most missed" panel markers (one of each per row)
# ---------------------------------------------------------------------------

const T2_MARKS = Dict(
    :best => (stroke = T2_HIT, tint = RGBAf(0.922, 0.408, 0.204, 0.10), text = "most correct"),
    :worst => (stroke = T2_MISS, tint = RGBAf(0.239, 0.235, 0.227, 0.10), text = "most missed"),
)

# Mean score of the selected regions (1 = always the peak): tiebreak for equal hit rates.
t2_mean_score(df) = sum(df.n_selected .* df.score) / max(sum(df.n_selected), 1)

"""
    t2_row_marks(keys, hit_rate, mean_score)

Dict key => :best / :worst for one row. Ranked by hit rate, ties broken by
mean selected score. Exact ties on both are all marked; nothing is marked
when every panel in the row is identical.
"""
function t2_row_marks(keys, hit_rate, mean_score)
    rank = collect(zip(hit_rate, round.(mean_score; digits = 6)))
    marks = Dict{eltype(keys),Symbol}()
    allequal(rank) && return marks
    hi, lo = maximum(rank), minimum(rank)
    for (k, r) in zip(keys, rank)
        r == hi && (marks[k] = :best)
        r == lo && (marks[k] = :worst)
    end
    marks
end

# Draw the highlight frame first so it sits behind the (transparent) axis.
function t2_mark_box!(cell, kind)
    isnothing(kind) && return
    m = T2_MARKS[kind]
    Box(cell; color = m.tint, strokecolor = m.stroke, strokewidth = 2.2, cornerradius = 8)
end

# The frame + legend identify marked panels; the subtitle stays short so
# neighbouring subtitles never collide.
t2_subtitle(rate, n, _kind = nothing) = @sprintf("%d%% hits · n = %d", round(Int, 100rate), n)

# ---------------------------------------------------------------------------
# Shared legend row
# ---------------------------------------------------------------------------

const T2_LEGEND_RESPONSES = Dict(
    :hit => "Hit (peak region)", :near => "Near hit (borders peak)", :miss => "Miss")
const T2_LEGEND_REGIONS = Dict(
    :peak => (T2_PEAK_STROKE, 2.2, "Peak region"), :near => (T2_NEAR, 1.6, "Neighbouring regions"))

"""
    t2_legend!(slot, geo; panel, truth_title, colorrange, classes, regions, panels, ncols)

Legend of equal-width, top-aligned blocks, each with the same title style:
ground-truth colour scale | dot-size key | responses | regions | panels.
Blocks wrap after `ncols` columns. `regions = ()` drops the Regions block.
`panel_scope` names what "most correct / most missed" is ranked within.
"""
function t2_legend!(slot, geo; panel, truth_title, colorrange, classes = (:hit, :miss),
                    regions = (:peak,), panels = true, panel_scope = "row",
                    shares = (0.05, 0.2, 0.5), block_width = 230, ncols = 5)
    gl = slot[] = GridLayout(; halign = :center, tellwidth = false)
    nblock = Ref(0)
    function block!(title)
        nblock[] += 1
        r, c = cld(nblock[], ncols), mod1(nblock[], ncols)
        b = gl[r, c] = GridLayout(; valign = :top, halign = :left)
        Label(b[1, 1], title; fontsize = T2_FS.legend_title, font = :bold, color = T2_INK2,
            halign = :left, tellwidth = false)
        rowgap!(b, 8)
        b
    end
    legend!(b, elements, labels) = Legend(b[2, 1], elements, labels;
        framevisible = false, padding = (0, 0, 0, 0), rowgap = 5, patchsize = (18, 18), patchlabelgap = 8,
        labelsize = T2_FS.legend, labelcolor = T2_INK, halign = :left, valign = :top, tellwidth = false)

    b = block!(truth_title)
    ticks = range(colorrange[1], colorrange[2]; length = T2_TRUTH_NBINS + 1)
    Colorbar(b[2, 1]; colormap = T2_TRUTH_CMAP, limits = colorrange, vertical = false,
        ticks = (collect(ticks), [@sprintf("%g", round(t; digits = 2)) for t in ticks]),
        width = block_width - 30, height = 12, ticklabelsize = T2_FS.tick, ticklabelcolor = T2_INK2,
        halign = :left, tellwidth = false)

    # Dot size key drawn in data space at the panels' px-per-unit scale, so the
    # key dots are exactly as large as the same shares in the panels.
    b = block!("Share of responses")
    px_per_unit = panel / (2.08 * geo.head.radius)  # matches limits! in t2_panel!
    ax = Axis(b[2, 1]; width = 220 * px_per_unit, height = 95 * px_per_unit, halign = :left, tellwidth = false)
    hidedecorations!(ax); hidespines!(ax)
    xs = Float32[25, 90, 175]
    scatter!(ax, xs, fill(55f0, 3); markersize = T2_DOT_SCALE .* sqrt.(collect(shares)),
        markerspace = :data, color = T2_MISS, strokecolor = :white, strokewidth = 0.7)
    text!(ax, xs, fill(10f0, 3); text = [@sprintf("%d%%", round(Int, 100s)) for s in shares],
        align = (:center, :center), fontsize = T2_FS.tick, color = T2_INK2)
    limits!(ax, 0, 220, 0, 95)

    b = block!("Responses")
    legend!(b, Any[MarkerElement(marker = :circle, color = T2_CLASS_COLORS[c], markersize = 15) for c in classes],
        [T2_LEGEND_RESPONSES[c] for c in classes])

    if !isempty(regions)
        b = block!("Regions")
        legend!(b, Any[PolyElement(color = :transparent, strokecolor = T2_LEGEND_REGIONS[r][1],
                    strokewidth = T2_LEGEND_REGIONS[r][2]) for r in regions],
            [T2_LEGEND_REGIONS[r][3] for r in regions])
    end

    if panels
        b = block!("Panels")
        legend!(b, Any[PolyElement(color = T2_MARKS[k].tint, strokecolor = T2_MARKS[k].stroke, strokewidth = 2.2)
                       for k in (:best, :worst)],
            ["Most correct in $panel_scope", "Most missed in $panel_scope"])
    end

    for c in 1:min(nblock[], ncols)
        colsize!(gl, c, Fixed(block_width))
    end
    colgap!(gl, 28)
    nblock[] > ncols && rowgap!(gl, 18)
    gl
end

# Stimulus figures: 10 stimuli per pattern wrap into 2 rows of 5, so panels
# stay large enough for legible subtitles at the final display width.
const T2_STIM_COLS = 5
t2_stim_cell(p, i) = (2(p - 1) + cld(i, T2_STIM_COLS), mod1(i, T2_STIM_COLS) + 1)

function t2_stim_row_labels!(fig)
    for (p, pat) in enumerate(T2_PATTERNS)
        Label(fig[2p-1:2p, 1], pat; rotation = π / 2, fontsize = T2_FS.row, font = :bold, color = T2_INK)
    end
end

function t2_stim_gaps!(fig)
    colgap!(fig.layout, 12)
    rowgap!(fig.layout, 10)
    for p in 1:length(T2_PATTERNS)-1
        rowgap!(fig.layout, 2p, Fixed(34))   # extra space between pattern blocks
    end
end

# ---------------------------------------------------------------------------
# Figure 1: every stimulus, pooled over visualization types
# ---------------------------------------------------------------------------

function t2_stimulus_figure(stim, geo; panel = 200)
    all_df = filter(:vistype => ==("all"), stim)
    fig = Figure(size = (T2_STIM_COLS * panel + 200, 6 * (panel + 50) + 300), backgroundcolor = :white)
    t2_stim_row_labels!(fig)
    for (p, pat) in enumerate(T2_PATTERNS)
        pdf = filter(:pattern => ==(pat), all_df)
        order = combine(groupby(pdf, :stimulus), :stimulus_hit_rate => first => :h, :subject => first => :s)
        sort!(order, [:h, :s]; rev = [true, false])
        msc = [t2_mean_score(filter(:stimulus => ==(s), pdf)) for s in order.stimulus]
        marks = t2_row_marks(order.stimulus, order.h, msc)
        for (i, s) in enumerate(order.stimulus)
            sdf = sort(filter(:stimulus => ==(s), pdf), :region_number)
            kind = get(marks, s, nothing)
            cell = fig[t2_stim_cell(p, i)...]
            t2_mark_box!(cell, kind)
            ax = Axis(cell; width = panel, height = panel,
                title = s, titlesize = T2_FS.col, titlecolor = T2_INK,
                subtitle = t2_subtitle(sdf.stimulus_hit_rate[1], sdf.n_trials[1], kind),
                subtitlesize = T2_FS.subtitle, subtitlecolor = T2_INK2, titlegap = 2)
            prop = t2_vec(sdf, :prop_selected)
            t2_panel!(ax, geo; fill = t2_vec(sdf, :score), colorrange = (0, 1),
                prop_selected = prop, prop_hits = prop .* sdf.is_peak,
                peaks = sdf.region_number[sdf.is_peak])
        end
    end
    t2_legend!(fig[7, 1:T2_STIM_COLS+1], geo; panel, truth_title = "Region score (1 = peak)",
        colorrange = (0, 1), ncols = 3, panel_scope = "pattern")
    t2_stim_gaps!(fig)
    resize_to_layout!(fig)
    fig
end

# ---------------------------------------------------------------------------
# Figure 2: selected stimuli x visualization type
# ---------------------------------------------------------------------------

# Default: easiest and hardest stimulus of each pattern.
function t2_default_stimuli(stim)
    rates = unique(filter(:vistype => ==("all"), stim)[:, [:pattern, :stimulus, :subject, :stimulus_hit_rate]])
    out = String[]
    for pat in T2_PATTERNS
        r = sort(filter(:pattern => ==(pat), rates), [:stimulus_hit_rate, :subject]; rev = [true, false])
        push!(out, r.stimulus[1], r.stimulus[end])
    end
    out
end

function t2_vistype_figure(stim, geo; stimuli = t2_default_stimuli(stim), panel = 160)
    cols = vcat("all", T2_VISTYPES)
    fig = Figure(size = (length(cols) * panel + 160, length(stimuli) * (panel + 40) + 260), backgroundcolor = :white)
    for (row, s) in enumerate(stimuli)
        sdf_all = filter(:stimulus => ==(s), stim)
        # Rank only the 7 visualization types; the pooled column is a reference.
        vis = [filter(:vistype => ==(v), sdf_all) for v in T2_VISTYPES]
        marks = t2_row_marks(T2_VISTYPES, [d.stimulus_hit_rate[1] for d in vis], t2_mean_score.(vis))
        Label(fig[row, 1], s; rotation = π / 2, fontsize = T2_FS.row, font = :bold, color = T2_INK)
        for (col, v) in enumerate(cols)
            sdf = sort(filter(:vistype => ==(v), sdf_all), :region_number)
            title = row == 1 ? T2_VISTYPE_LABELS2[v] : ""
            kind = get(marks, v, nothing)
            t2_mark_box!(fig[row, col + 1], kind)
            ax = Axis(fig[row, col + 1]; width = panel, height = panel,
                title = title, titlesize = T2_FS.col, titlecolor = T2_INK,
                subtitle = t2_subtitle(sdf.stimulus_hit_rate[1], sdf.n_trials[1], kind),
                subtitlesize = T2_FS.subtitle, subtitlecolor = T2_INK2, titlegap = 2)
            prop = t2_vec(sdf, :prop_selected)
            t2_panel!(ax, geo; fill = t2_vec(sdf, :score), colorrange = (0, 1),
                prop_selected = prop, prop_hits = prop .* sdf.is_peak,
                peaks = sdf.region_number[sdf.is_peak])
        end
    end
    t2_legend!(fig[length(stimuli)+1, 1:length(cols)+1], geo; panel,
        truth_title = "Region score (1 = peak)", colorrange = (0, 1), block_width = 220)
    colgap!(fig.layout, 8); rowgap!(fig.layout, 12)
    resize_to_layout!(fig)
    fig
end

# ---------------------------------------------------------------------------
# Figure 3: pattern x visualization type (stimuli pooled)
# ---------------------------------------------------------------------------

function t2_pattern_vistype_figure(reg, stim, geo; panel = 165)
    cmax = ceil(maximum(reg.prop_correct) * 10) / 10
    fig = Figure(size = (7 * panel + 120, 3 * (panel + 50) + 260), backgroundcolor = :white)
    for (row, pat) in enumerate(T2_PATTERNS)
        rate = [let d = filter(r -> r.pattern == pat && r.vistype == v, reg)
                    sum(d.n_hits) / d.n_trials[1] end for v in T2_VISTYPES]
        msc = [t2_mean_score(filter(r -> r.pattern == pat && r.vistype == v, stim)) for v in T2_VISTYPES]
        marks = t2_row_marks(T2_VISTYPES, rate, msc)
        Label(fig[row, 1], pat; rotation = π / 2, fontsize = T2_FS.row, font = :bold, color = T2_INK)
        for (col, v) in enumerate(T2_VISTYPES)
            rdf = sort(filter(r -> r.pattern == pat && r.vistype == v, reg), :region_number)
            hits = sum(rdf.n_hits); n = rdf.n_trials[1]
            kind = get(marks, v, nothing)
            t2_mark_box!(fig[row, col + 1], kind)
            ax = Axis(fig[row, col + 1]; width = panel, height = panel,
                title = row == 1 ? T2_VISTYPE_LABELS2[v] : "", titlesize = T2_FS.col, titlecolor = T2_INK,
                subtitle = t2_subtitle(hits / n, n, kind),
                subtitlesize = T2_FS.subtitle, subtitlecolor = T2_INK2, titlegap = 2)
            t2_panel!(ax, geo; fill = t2_vec(rdf, :prop_correct), colorrange = (0, cmax),
                prop_selected = t2_vec(rdf, :prop_selected), prop_hits = t2_vec(rdf, :prop_hits))
        end
    end
    t2_legend!(fig[4, 1:8], geo; panel, truth_title = "Share of trials region was peak",
        colorrange = (0, cmax), regions = (), block_width = 250)
    colgap!(fig.layout, 8); rowgap!(fig.layout, 12)
    resize_to_layout!(fig)
    fig
end

# ---------------------------------------------------------------------------
# Hit / near hit / miss
# ---------------------------------------------------------------------------

# Region class for one stimulus: :hit (peak), :near (borders a peak), :miss.
function t2_region_classes(geo, peaks)
    cls = fill(:miss, 64)
    for k in peaks, j in geo.adj[k]
        cls[j] = :near
    end
    cls[peaks] .= :hit
    cls
end

const T2_CLASS_COLORS = Dict(:hit => T2_HIT, :near => T2_NEAR, :miss => T2_MISS)
const T2_CLASS_LABELS = Dict(:hit => "Hit", :near => "Near hit", :miss => "Miss")

# Long table: one row per stimulus x vistype with hit / near / miss counts.
function t2_hit_near_miss_counts(stim, geo)
    rows = NamedTuple[]
    for g in groupby(stim, [:pattern, :stimulus, :vistype])
        d = sort(g, :region_number)
        cls = t2_region_classes(geo, d.region_number[d.is_peak])
        push!(rows, (pattern = d.pattern[1], stimulus = d.stimulus[1], vistype = d.vistype[1],
            n_trials = d.n_trials[1],
            hit = sum(d.n_selected[cls .== :hit]),
            near = sum(d.n_selected[cls .== :near]),
            miss = sum(d.n_selected[cls .== :miss])))
    end
    out = DataFrame(rows)
    all(out.hit .+ out.near .+ out.miss .== out.n_trials) || error("Class counts do not sum to n_trials.")
    out
end

function t2_panel_classes!(ax, geo; fill, prop_selected, cls)
    hidedecorations!(ax); hidespines!(ax)
    ax.aspect = DataAspect()
    ax.backgroundcolor = :transparent
    c, r = geo.head.center, geo.head.radius
    limits!(ax, c[1] - 1.04r, c[1] + 1.04r, c[2] - 1.04r, c[2] + 1.13r)
    for k in 1:64
        poly!(ax, geo.polys[k]; color = t2_truth_color(fill[k]), strokecolor = :white, strokewidth = 0.6)
    end
    for k in findall(==(:near), cls)
        poly!(ax, geo.polys[k]; color = :transparent, strokecolor = T2_NEAR, strokewidth = 1.6)
    end
    for k in findall(==(:hit), cls)
        poly!(ax, geo.polys[k]; color = :transparent, strokecolor = T2_PEAK_STROKE, strokewidth = 2.2)
    end
    t2_draw_head!(ax, geo.head)
    sel = findall(>(0), prop_selected)
    isempty(sel) || scatter!(ax, geo.centroids[sel];
        markersize = T2_DOT_SCALE .* sqrt.(prop_selected[sel]), markerspace = :data,
        color = [T2_CLASS_COLORS[cls[k]] for k in sel], strokecolor = :white, strokewidth = 0.7)
    ax
end

# Figure 4: every stimulus (pooled over visualizations), hit / near hit / miss.
function t2_near_stimulus_figure(stim, counts, geo; panel = 200)
    all_df = filter(:vistype => ==("all"), stim)
    allc = filter(:vistype => ==("all"), counts)
    fig = Figure(size = (T2_STIM_COLS * panel + 200, 6 * (panel + 50) + 300), backgroundcolor = :white)
    t2_stim_row_labels!(fig)
    for (p, pat) in enumerate(T2_PATTERNS)
        pc = filter(:pattern => ==(pat), allc)
        pc.hit_rate = pc.hit ./ pc.n_trials
        pc.close_rate = (pc.hit .+ pc.near) ./ pc.n_trials  # hit or near hit
        sort!(pc, [order(:hit_rate, rev = true), order(:close_rate, rev = true), :stimulus])
        # Rank by hit rate; ties broken by hit-or-near-hit rate.
        marks = t2_row_marks(pc.stimulus, pc.hit_rate, pc.close_rate)
        for (i, s) in enumerate(pc.stimulus)
            sdf = sort(filter(:stimulus => ==(s), all_df), :region_number)
            cr = pc[i, :]
            kind = get(marks, s, nothing)
            cell = fig[t2_stim_cell(p, i)...]
            t2_mark_box!(cell, kind)
            ax = Axis(cell; width = panel, height = panel,
                title = s, titlesize = T2_FS.col, titlecolor = T2_INK,
                subtitle = @sprintf("hit %d%% · near %d%% · n = %d", round(Int, 100cr.hit / cr.n_trials),
                    round(Int, 100cr.near / cr.n_trials), cr.n_trials),
                subtitlesize = T2_FS.subtitle, subtitlecolor = T2_INK2, titlegap = 2)
            t2_panel_classes!(ax, geo; fill = t2_vec(sdf, :score), prop_selected = t2_vec(sdf, :prop_selected),
                cls = t2_region_classes(geo, sdf.region_number[sdf.is_peak]))
        end
    end
    t2_legend!(fig[7, 1:T2_STIM_COLS+1], geo; panel, truth_title = "Region score (1 = peak)", colorrange = (0, 1),
        classes = (:hit, :near, :miss), regions = (:peak, :near), ncols = 3, panel_scope = "pattern")
    t2_stim_gaps!(fig)
    resize_to_layout!(fig)
    fig
end

# Figure 5: hits and near hits per visualization type, by pattern.
# Side-by-side bars, each from zero (Wilke ch. 10: interior segments of a
# stacked bar cannot be compared because both their ends move). Misses are the
# remainder and are listed on the analysis page.
function t2_near_vistype_figure(counts)
    vc = filter(:vistype => !=("all"), counts)
    agg(df) = combine(groupby(df, :vistype), [:hit, :near, :miss, :n_trials] .=> sum .=> [:hit, :near, :miss, :n])
    facets = vcat([("All patterns", agg(vc))], [(p, agg(filter(:pattern => ==(p), vc))) for p in T2_PATTERNS])
    shares_of(d) = (hit = d.hit ./ d.n, near = d.near ./ d.n)
    xmax = ceil(maximum(maximum(vcat(shares_of(d).hit, shares_of(d).near)) for (_, d) in facets) * 10 + 0.5) / 10

    fig = Figure(size = (1150, 980), backgroundcolor = :white, figure_padding = (16, 30, 16, 16))
    ys = Float64.(length(T2_VISTYPES):-1:1)  # first vistype on top
    bw, off = 0.36, 0.19                      # bar width, offset of hit (up) / near (down)
    for (k, (name, d)) in enumerate(facets)
        d = d[indexin(T2_VISTYPES, d.vistype), :]
        s = shares_of(d)
        r, c = cld(k, 2), mod1(k, 2)
        ax = Axis(fig[r, c]; title = name, titlesize = 16, titlecolor = T2_INK,
            subtitle = @sprintf("n = %d responses per bar", d.n[1]), subtitlesize = T2_FS.subtitle,
            subtitlecolor = T2_INK2,
            yticks = (ys, [T2_VISTYPE_LABELS[v] for v in T2_VISTYPES]), yticklabelsize = 14,
            yticklabelsvisible = c == 1, yticklabelcolor = T2_INK, xticklabelcolor = T2_INK2, xticklabelsize = 13,
            xticks = (0:0.1:xmax, [@sprintf("%d%%", round(Int, 100t)) for t in 0:0.1:xmax]),
            xgridcolor = RGBAf(0, 0, 0, 0.08), ygridvisible = false,
            xlabel = r == 2 ? "Share of responses" : "", xlabelcolor = T2_INK2, xlabelsize = 14,
            width = 400, height = 330)
        hidespines!(ax, :t, :r, :l)
        for (cls, dy) in ((:hit, off), (:near, -off))
            v = getproperty(s, cls)
            barplot!(ax, ys .+ dy, v; direction = :x, width = bw, color = T2_CLASS_COLORS[cls],
                strokecolor = :white, strokewidth = 1)
            text!(ax, v .+ 0.006, ys .+ dy; text = [@sprintf("%d%%", round(Int, 100x)) for x in v],
                align = (:left, :center), fontsize = 12, color = T2_INK2)
        end
        xlims!(ax, 0, xmax); ylims!(ax, 0.4, length(T2_VISTYPES) + 0.6)
    end
    Legend(fig[3, 1:2], [PolyElement(color = T2_CLASS_COLORS[c]) for c in (:hit, :near)],
        ["Hit (peak region)", "Near hit (borders the peak)"];
        framevisible = false, orientation = :horizontal, labelsize = T2_FS.legend, labelcolor = T2_INK,
        patchsize = (18, 18), colgap = 28)
    colgap!(fig.layout, 36); rowgap!(fig.layout, 24)
    resize_to_layout!(fig)
    fig
end

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

function t2_save(fig, name)
    mkpath(T2_FIG_DIR)
    png = joinpath(T2_FIG_DIR, name * ".png")
    save(png, fig; px_per_unit = 2)
    save(joinpath(T2_FIG_DIR, name * ".pdf"), fig)
    png
end

function t2_main()
    geo = t2_load_regions()
    stim = CSV.read(joinpath(T2_DATA_DIR, "task2_hits_misses_stimulus.csv"), DataFrame)
    reg = CSV.read(joinpath(T2_DATA_DIR, "task2_hits_misses_regions.csv"), DataFrame)
    stim.is_peak = Bool.(stim.is_peak)
    paths = [
        t2_save(t2_stimulus_figure(stim, geo), "task2_hits_misses_by_stimulus"),
        t2_save(t2_vistype_figure(stim, geo), "task2_hits_misses_stimulus_by_vistype"),
        t2_save(t2_pattern_vistype_figure(reg, stim, geo), "task2_hits_misses_pattern_by_vistype"),
    ]
    counts = t2_hit_near_miss_counts(stim, geo)
    push!(paths,
        t2_save(t2_near_stimulus_figure(stim, counts, geo), "task2_hit_near_miss_by_stimulus"),
        t2_save(t2_near_vistype_figure(counts), "task2_hit_near_miss_by_vistype"))
    summary = combine(groupby(filter(:vistype => !=("all"), counts), :vistype),
        [:hit, :near, :miss, :n_trials] .=> sum .=> [:hit, :near, :miss, :n])
    for c in (:hit, :near, :miss)
        summary[!, Symbol(c, :_pct)] = round.(100 .* summary[!, c] ./ summary.n; digits = 1)
    end
    println(summary)
    println("Neighbours per region: ", extrema(length.(geo.adj)), ", mean ", round(mean(length.(geo.adj)); digits = 2))
    foreach(println, paths)
    paths
end

if abspath(PROGRAM_FILE) == @__FILE__
    t2_main()
end

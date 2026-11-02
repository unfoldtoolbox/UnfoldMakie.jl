include("individual_uncert.jl")
@isdefined(task_configs_30) || include("../stimuli_data.jl")
@isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")

# This file works from cached avgref CSV tables, not raw ERP tables.
load_stimulus_subject_avgref_or_nothing(cfg; subject) =
    load_erp_subject_avgref_or_nothing(
        cfg.task;
        subject = subject,
        timepoint = cfg.timepoint,
        condition = cfg.condition,
    )

stimulus_signal(subject_data) = avgref_signal(subject_data)
stimulus_se(subject_data) = Float64.(subject_data.se)
stimulus_abs_t(subject_data) = avgref_abs_t(subject_data)

function combined_uncerts_cat(
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    enable_contour=true,
    uncert_label="Standard deviation",
    tv=false,
)
    BG = RGBf(0.98, 0.98, 0.98)
    f = Figure(backgroundcolor=BG, size=(1200, 1100), figure_padding=(20, 20, 20, 50))

    ga = f[1, 1] = GridLayout(); gb = f[1, 2] = GridLayout()
    gc = f[2, 1] = GridLayout(); gd = f[2, 2] = GridLayout()
    ge = f[3, 1] = GridLayout(); gf = f[3, 2] = GridLayout()

    common = (; positions, labels, uncert_label)
    range_order = tv ? :high_to_low : :low_to_high
    vsp_reverse = tv ? true : false

    plot_adjacent!(ga, vec_estimate, vec_uncert; common..., enable_contour, BG)
    plot_bivariate_corner!(gb, vec_estimate, vec_uncert; common..., BG)
    plot_bivariate_range!(gc, vec_estimate, vec_uncert; common..., order_vertical=range_order, enable_contour, hatch=true, BG)
    plot_uncert_markers!(ge, vec_estimate, vec_uncert; common..., enable_contour, BG)

    tv ?
        plot_vsp!(gd, vec_estimate, vec_uncert; common..., enable_contour, reverse_vsp_rows=vsp_reverse) :
        plot_triple_CI!(gf, vec_estimate, vec_uncert; common..., BG)

    labs, lays = tv ?
        (["A. Adjacent", "B. Bivariate corners", "C. Bivariate range", "D. Value-suppressing palette", "E. Marker size change"],
         [ga, gb, gc, gd, ge]) :
        (["A. Adjacent", "B. Bivariate corners", "C. Bivariate range", "D. Marker size change", "E. Confidence intervals"],
         [ga, gb, gc, ge, gf])

    for (lab, lay) in zip(labs, lays)
        Label(
            lay[1, 1, TopLeft()], lab;
            fontsize=26, font=:bold, padding=(20, -15, 20, 0),
            halign=:left, tellwidth=false, tellheight=false,
        )
    end

    f
end

# Example:
# subject_data = load_erp_subject_avgref("P3"; subject = 11, timepoint = 129, condition = 1)
# combined_uncerts_cat(stimulus_signal(subject_data), stimulus_se(subject_data); labels = subject_data.labels, uncert_label = "SE")
# combined_uncerts_cat(stimulus_signal(subject_data), stimulus_abs_t(subject_data); labels = subject_data.labels, tv = true, uncert_label = "|t|-value")

function combined_uncerts_cat_save(
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    enable_contour=true,
    uncert_label="Standard deviation",
    tv=false,
    BG=:white,
    outdir="stimuli",
    fig_size=(600, 500),
    file_name = "test"
)
    mkpath(outdir)

    common = (; positions, labels, uncert_label)
    range_order = tv ? :high_to_low : :low_to_high
    vsp_reverse = tv
    saved = String[]

    plots = [
        ("adjacent.png",         slot -> plot_adjacent!(slot, vec_estimate, vec_uncert; common..., enable_contour, BG)),
        ("bivariate_corner.png", slot -> plot_bivariate_corner!(slot, vec_estimate, vec_uncert; common..., BG)),
        ("bivariate_range.png",  slot -> plot_bivariate_range!(slot, vec_estimate, vec_uncert; common..., order_vertical=range_order, enable_contour, hatch=true, BG)),
        ("uncert_markers.png",   slot -> plot_uncert_markers!(slot, vec_estimate, vec_uncert; common..., enable_contour, BG)),
        tv ?
            ("vsp.png",          slot -> plot_vsp!(slot, vec_estimate, vec_uncert; common..., enable_contour, reverse_vsp_rows=vsp_reverse)) :
            ("triple_CI.png",    slot -> plot_triple_CI!(slot, vec_estimate, vec_uncert; common..., BG)),
    ]
    for (name, plotfun) in plots
        #pad = occursin("bivariate", name) ? (16, 16, -20, 10) : (16, 16, 16, 10)
        pad = occursin("bivariate", name) ? (16, 16, -20, 10) :
            occursin("vsp", name)       ? (16, -10, 16, 10)  :
                                            (16, 16, 16, 10)
        f = Figure(size=fig_size, backgroundcolor=BG, figure_padding=pad)
        plotfun(f[1, 1])
        filename = "$(file_name)_$(name)"
        path = joinpath(outdir, filename)
        save(path, f)
        push!(saved, path)
    end

    saved
end

for cfg in task_configs_30_balanced
    for subj in cfg.subjects
        subject_data = load_stimulus_subject_avgref_or_nothing(cfg; subject = subj)
        isnothing(subject_data) && continue

        signal = stimulus_signal(subject_data)
        se = stimulus_se(subject_data)

        combined_uncerts_cat_save(
            signal, se;
            fig_size = (500, 300),
            labels = subject_data.labels,
            tv = false,
            uncert_label = "SE",
            outdir = joinpath("experiments", "stimuli"),
            file_name = "$(cfg.task)_$(subj)",
        )
    end
end

for cfg in task_configs_30_balanced
    for subj in cfg.subjects
        subject_data = load_stimulus_subject_avgref_or_nothing(cfg; subject = subj)
        isnothing(subject_data) && continue

        signal = stimulus_signal(subject_data)
        se = stimulus_se(subject_data)

        f_se, obs_se, boot_means_se = plot_HOP(signal, se; labels = subject_data.labels, uncert_label = "")

        se_path = joinpath("experiments", "stimuli", "anim_30", "$(cfg.task)_$(subj)_animation.gif")
        create_HOP_gif(f_se, obs_se, boot_means_se; filepath = se_path)
    end
end



function save_basic_stimulus_topoplot(
    cfg;
    subject,
    outdir = joinpath("experiments", "stimuli"),
)
    subject_data = load_stimulus_subject_avgref_or_nothing(cfg; subject = subject)
    isnothing(subject_data) && return nothing
    signal = stimulus_signal(subject_data)
    signal_lims = _shared_scalar_topoplot_range(signal; colorrange_mode = :diverging_balanced)
    signal_ticks = Float32[signal_lims[1], signal_lims[1] / 2, 0f0, signal_lims[2] / 2, signal_lims[2]]
    signal_ticklabels = [
        isapprox(Float64(tick), 0.0; atol = 1e-12) ? "0" : @sprintf("%.1f", Float64(tick))
        for tick in signal_ticks
    ]

    fig = plot_topoplot(
        signal;
        labels = subject_data.labels,
        axis = (; xlabel = ""),
        visual = (;
            contours = true,
            colormap = cgrad(:RdYlBu, 10; categorical = true, rev = true),
            colorrange_mode = :diverging_balanced,
        ),
        colorbar = (;
            label = "Voltage [µV]",
            labelsize = 24,
            ticklabelsize = 18,
            height = 350,
            ticks = (signal_ticks, signal_ticklabels),
        ),
    )

    mkpath(outdir)
    filepath = joinpath(outdir, "$(cfg.task)_$(subject)_basic.png")
    save(filepath, fig)
    filepath
end

function save_basic_stimuli(
    configs = task_configs_30;
    outdir = joinpath("experiments", "stimuli"),
)
    saved = String[]

    for cfg in configs
        for subj in cfg.subjects
            filepath = save_basic_stimulus_topoplot(
                cfg;
                subject = subj,
                outdir = outdir,
            )
            isnothing(filepath) || push!(saved, filepath)
        end
    end

    saved
end
# Scratch examples kept here on purpose, but commented out to avoid work on include.
#=
save_basic_stimuli(task_configs_30_balanced)

begin
    @isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")
    cfg = (task = "N170", subjects = [6], timepoint = 105, condition = 2)
    subject = first(cfg.subjects)
    subject_data = load_erp_subject_avgref_or_nothing(
        cfg.task;
        subject = subject,
        timepoint = cfg.timepoint,
        condition = cfg.condition,
    )
    isnothing(subject_data) && error("Missing avgref CSV for $(cfg.task)_$(subject).")

    fig = Figure(size = (500, 300), backgroundcolor = :white, figure_padding = (16, 16, -20, 10))
    plot_bivariate_corner!(
        fig[1, 1],
        avgref_signal(subject_data),
        Float64.(subject_data.se);
        labels = subject_data.labels,
        uncert_label = "SE",
        colorbox = _colorbox_corner_teuling3,
        hatch = true,
    )
    fig
end

begin
    cfg = (task = "N170", subjects = [6], timepoint = 105, condition = 2)
    subject = first(cfg.subjects)
    subject_data = load_erp_subject_avgref_or_nothing(
        cfg.task;
        subject = subject,
        timepoint = cfg.timepoint,
        condition = cfg.condition,
    )
    isnothing(subject_data) && error("Missing avgref CSV for $(cfg.task)_$(subject).")

    fig = Figure(size = (500, 300), backgroundcolor = :white, figure_padding = (16, 16, -20, 10))
    plot_bivariate_corner!(
        fig[1, 1],
        avgref_signal(subject_data),
        Float64.(subject_data.se);
        labels = subject_data.labels,
        uncert_label = "SE",
        colorbox = _colorbox_corner_teuling,
        hatch = true,
    )
    fig
end

begin
    @isdefined(load_erp_subject_avgref_or_nothing) || include("../region_detection/rereferencing.jl")
    cfg = (task = "P3", subjects = [4], timepoint = 129, condition = 1)
    subject = first(cfg.subjects)
    subject_data = load_erp_subject_avgref_or_nothing(
        cfg.task;
        subject = subject,
        timepoint = cfg.timepoint,
        condition = cfg.condition,
    )
    isnothing(subject_data) && error("Missing avgref CSV for $(cfg.task)_$(subject).")

    fig = Figure(size = (500, 300), backgroundcolor = :white, figure_padding = (16, 16, -20, 10))
    plot_bivariate_corner!(
        fig[1, 1],
        avgref_signal(subject_data),
        Float64.(subject_data.se);
        labels = subject_data.labels,
        uncert_label = "SE",
        colorbox = _colorbox_corner_teuling3,
        hatch = true,
    )
    fig
end
=#

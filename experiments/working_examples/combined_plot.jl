

function hide_axis!(ax)
    hidedecorations!(ax, label = false)
    hidespines!(ax)
    return ax
end
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
    plot_bivariate_corner!(gb, vec_estimate, vec_uncert; common...)
    plot_bivariate_range!(gc, vec_estimate, vec_uncert; common..., order_vertical=range_order, enable_contour)
    plot_uncert_markers!(ge, vec_estimate, vec_uncert; common..., enable_contour)

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

combined_uncerts_cat(test.estimate .- 4.55, test.se; labels = test.labels, uncert_label = "SE")
combined_uncerts_cat(test.estimate .- 4.55, test.abs_t; labels = test.labels, tv = true, uncert_label = "|t|-value")

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
        ("bivariate_corner.png", slot -> plot_bivariate_corner!(slot, vec_estimate, vec_uncert; common...)),
        ("bivariate_range.png",  slot -> plot_bivariate_range!(slot, vec_estimate, vec_uncert; common..., order_vertical=range_order, enable_contour)),
        ("uncert_markers.png",   slot -> plot_uncert_markers!(slot, vec_estimate, vec_uncert; common..., enable_contour)),
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


configs_tasks = [
    (task = "MMN",  subjects = [20, 25, 26], timepoint = 96,  condition = 3, shift = 0.0),
    (task = "P3",   subjects = [11, 12, 16], timepoint = 128, condition = 1, shift = 4.55),
    (task = "N170", subjects = [26, 5, 12],  timepoint = 105, condition = 2, shift = 0.0),
]

for cfg in configs_tasks
    for subj in cfg.subjects
        test1 = load_erp_subject(
            cfg.task;
            subject = subj,
            timepoint = cfg.timepoint,
            condition = cfg.condition,
        )

        #est = test1.estimate #.- cfg.shift
        est = iszero(cfg.shift) ? test1.estimate : test1.estimate .- cfg.shift

        combined_uncerts_cat_save(
            est, test1.abs_t;
            fig_size = (500, 300),
            labels = test1.labels,
            tv = true,
            uncert_label = "|t|-value",
            outdir = joinpath("stimuli", "t"),
            file_name = "$(cfg.task)_$(subj)",
        )

        combined_uncerts_cat_save(
            est, test1.se;
            fig_size = (500, 300),
            labels = test1.labels,
            tv = false,
            uncert_label = "SE",
            outdir = joinpath("stimuli", "SE"),
            file_name = "$(cfg.task)_$(subj)",
        )
    end
end

configs_tasks = [
    (task = "MMN",  subjects = [20, 25, 26], timepoint = 96,  condition = 3, shift = 0.0),
    (task = "P3",   subjects = [11, 12, 16], timepoint = 128, condition = 1, shift = 4.55),
    (task = "N170", subjects = [26, 5, 12],  timepoint = 105, condition = 2, shift = 0.0),
]
test = load_erp_subject(
            cfg.task;
            subject = subj,
            timepoint = cfg.timepoint,
            condition = cfg.condition,
        )
test = load_erp_subject(
            "N170";
            subject = 26,
            timepoint = 105,
            condition = 1,
        )
f, obs, boot_means = plot_HOP(test.estimate, test.se; labels = test.labels, uncert_label = "SE")
f
create_HOP_gif(f, obs, boot_means)



for cfg in configs_tasks
    for subj in cfg.subjects
        test = load_erp_subject(
            cfg.task;
            subject = subj,
            timepoint = cfg.timepoint,
            condition = cfg.condition,
        )

        est = test.estimate .- cfg.shift
        # --- SE version ---
        f_se, obs_se, boot_means_se = plot_HOP(est, test.se; labels = test.labels, uncert_label = "")

        se_path = joinpath("stimuli", "se", "$(cfg.task)_$(subj)_anim.gif")
        create_HOP_gif(f_se, obs_se, boot_means_se; filepath = se_path)

        # --- t version ---
        f_t, obs_t, boot_means_t = plot_HOP(est, test.abs_t; labels = test.labels, uncert_label = "")

        t_path = joinpath("stimuli", "t", "$(cfg.task)_$(subj)_anim.gif")
        create_HOP_gif(f_t, obs_t, boot_means_t; filepath = t_path)
    end
end

for cfg in configs_tasks
    for subj in cfg.subjects
        test = load_erp_subject(
            cfg.task;
            subject = subj,
            timepoint = cfg.timepoint,
            condition = cfg.condition,
        )

        est = test.estimate .- cfg.shift
        # --- SE version ---
        f = plot_topoplot(
            test;
            labels = test.labels,
            axis = (; xlabel = ""),
            visual = (; contours=true, colormap=cgrad(:RdYlBu, 10; categorical=true, rev = true)),
            colorbar = (; labelsize=24, ticklabelsize=18, height=350),
        )

        path = joinpath("stimuli", "basic", "$(cfg.task)_$(subj)_basic.png")
        save(path, f)
    end
end


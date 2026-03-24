using MAT
function load_erp(subj, task)
    osf_dataset = task_osf_dict[task]
    osf_proj = OSF.project(OSF.Client(), osf_dataset)

    ix = findfirst(occursin.("All Data and Scripts", basename.(readdir(osf_proj))))
    data_dir = readdir(osf_proj)[ix]
    osf_task_subj_folder = joinpath(data_dir, string(subj))

    fn = readdir(osf_task_subj_folder)

    local_name = joinpath("/scratch/users/mikheev/erpcore",
        "erpcore_$(subj)_$(task).erp")

    if !isfile(local_name)
        cp(fn[occursin.("erp_ar.erp", basename.(fn))][1], local_name)
    end

    MAT.matread(local_name)["ERP"]
end
#= 

function df_from_cached_erps(task; timepoint=92, condition=1,
    cache_dir="/scratch/users/mikheev/erpcore")

    files = readdir(cache_dir; join=true)
    pat = Regex("^erpcore_(\\d+)_$(task)\\.erp")

    task_files = filter(f -> occursin(pat, basename(f)), files)

    parsed = [
        (
            subject = parse(Int, match(pat, basename(f)).captures[1]),
            file = f,
        )
        for f in task_files
    ]

    sort!(parsed, by = x -> x.subject)

    dfs = DataFrame[]

    for p in parsed
        println("subject $(p.subject) ← $(basename(p.file))")
        erp = MAT.matread(p.file)["ERP"]
        vec_est = erp["bindata"][1:end-7, timepoint, condition]

        push!(dfs, DataFrame(
            estimate = vec_est,
            channel = 1:length(vec_est),
            subject = string(p.subject),
        ))
    end

    vcat(dfs...)
end
 =#


 function load_erp_subject(
    task;
    subject,
    timepoint=92,
    condition=1,
    cache_dir="/scratch/users/mikheev/erpcore",
)
    file = joinpath(cache_dir, "erpcore_$(subject)_$(task).erp")
    erp = MAT.matread(file)["ERP"]

    if condition == 3
        vec_est = erp["bindata"][1:end-7, timepoint, 1] .- erp["bindata"][1:end-7, timepoint, 2]
        vec_se  = erp["binerror"][1:end-7, timepoint, 1] .- erp["binerror"][1:end-7, timepoint, 2]
    else
        vec_est = erp["bindata"][1:end-7, timepoint, condition]
        vec_se  = erp["binerror"][1:end-7, timepoint, condition]
    end

    vec_t  = abs.(vec_est ./ vec_se)
    labels = vec(erp["chanlocs"]["labels"][1:end-7])

    return DataFrame(
        estimate = vec_est,
        se = vec_se,
        abs_t = vec_t,
        labels = labels,
        channels = 1:length(vec_est),
        subject = fill(string(subject), length(vec_est)),
        task = fill(string(task), length(vec_est)),
        condition = fill(condition, length(vec_est)),
        timepoint = fill(timepoint, length(vec_est)),
    )
end
# MMN
function plot_erp_subject_grid(
    subjects;
    timepoint=96,
    task="MMN",
    condition=3,
    figure_size=(850, 760),
)
    f = Figure(size = figure_size)

    gl_est = f[1, 1] = GridLayout()
    gl_se  = f[1, 2] = GridLayout()
    gl_biv = f[1, 3] = GridLayout()

    for (row, subj) in enumerate(subjects)
        df = load_erp_subject(task; subject=subj, timepoint=timepoint, condition=condition)

        est_axis = row == 1 ?
            (; title = "Mean", xlabel = "subj $subj", titlesize = 18) :
            (; xlabel = "subj $subj")

        se_axis = row == 1 ?
            (; title = "SE", xlabel = "subj $subj", titlesize = 18) :
            (; xlabel = "subj $subj")

        plot_topoplot!(gl_est[row, 1], df.estimate;
            labels = df.label,
            visual = (; colormap = Reverse(:RdYlBu)),
            axis = est_axis,
            colorbar = (; label = "", position = :bottom, vertical = false, width = 125)
        )

        plot_topoplot!(gl_se[row, 1], df.se;
            labels = df.label,
            visual = (; colormap = :viridis),
            axis = se_axis,
            colorbar = (; label = "", position = :bottom, vertical = false, width = 125)
        )

        plot_bivariate_corner!(gl_biv[row, 1], df.estimate, df.se;
            labels = df.label,
            ylabel = "SE"
        )
    end

    rowgap!(gl_biv, -80)

    return f
end

plot_erp_subject_grid(
    [20, 25, 26]; timepoint=96, task="MMN",
    condition=3, figure_size=(850, 760),
)

plot_erp_subject_grid(
    [11, 12, 16]; timepoint=128, task="P3",
    condition=1, figure_size=(850, 760),
)

plot_erp_subject_grid(
    [26, 5, 12]; timepoint=105, task="N170",
    condition=2, figure_size=(850, 760),
)
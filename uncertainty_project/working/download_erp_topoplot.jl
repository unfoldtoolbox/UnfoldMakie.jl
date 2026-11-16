"""
Download one ERP CORE file from OSF and create a simple scalp topoplot.

Install the required packages once in the Julia REPL:

    import Pkg
    Pkg.add(["CairoMakie", "MAT", "OpenScienceFramework", "UnfoldMakie"])

Then run this file:

    julia download_erp_topoplot.jl
"""

using CairoMakie
using MAT
using OpenScienceFramework
using UnfoldMakie

# -----------------------------------------------------------------------------
# Parameters
# -----------------------------------------------------------------------------

task = "P3"          # Available: "P3", "N2pc", "N170", or "MMN"
subject = 10          # ERP CORE subject number
condition = 1         # Experimental condition stored in the ERP file
time_ms = 300         # Plot the sample closest to this time in milliseconds

cache_dir = joinpath(@__DIR__, "erp_data")
output_file = joinpath(@__DIR__, "erp_topoplot.png")

# OSF component containing each ERP CORE task.
const TASK_OSF_IDS = Dict(
    "P3" => "etdkz",
    "N2pc" => "yefrq",
    "N170" => "pfde9",
    "MMN" => "5q4xs",
)

"""Return a local ERP file, downloading it from OSF when necessary."""
function download_erp(task, subject; cache_dir)
    haskey(TASK_OSF_IDS, task) ||
        throw(ArgumentError("Unknown task $(repr(task)). Choose one of $(join(keys(TASK_OSF_IDS), ", "))."))

    mkpath(cache_dir)
    local_file = joinpath(cache_dir, "erpcore_$(subject)_$(task).erp")

    if isfile(local_file)
        println("Using existing file: $local_file")
        return local_file
    end

    println("Downloading task $task, subject $subject from OSF ...")
    project = OSF.project(OSF.Client(), TASK_OSF_IDS[task])

    project_entries = readdir(project)
    data_index = findfirst(
        path -> occursin("All Data and Scripts", basename(path)),
        project_entries,
    )
    isnothing(data_index) && error("Could not find the data directory in the OSF project.")

    subject_dir = joinpath(project_entries[data_index], string(subject))
    subject_files = readdir(subject_dir)
    erp_index = findfirst(
        path -> occursin("erp_ar.erp", basename(path)),
        subject_files,
    )
    isnothing(erp_index) && error("Could not find the cleaned ERP file for subject $subject.")

    cp(subject_files[erp_index], local_file)
    println("Saved data to: $local_file")
    return local_file
end

# Download and read the MATLAB-format ERP file.
erp_file = download_erp(task, subject; cache_dir)
erp = MAT.matread(erp_file)["ERP"]

# ERP CORE stores seven non-EEG channels at the end; omit them for the topoplot.
times = vec(erp["times"])
time_index = argmin(abs.(times .- time_ms))
channel_labels = vec(erp["chanlocs"]["labels"][1:end-7])
values = vec(erp["bindata"][1:end-7, time_index, condition])

# Create and save a simple scalp topoplot.
figure = Figure(size = (650, 550))
plot_topoplot!(
    figure[1, 1],
    values;
    labels = channel_labels,
    visual = (; colormap = :RdBu),
    axis = (;
        title = "$task — subject $subject, condition $condition",
        xlabel = "$(round(times[time_index]; digits=1)) ms",
    ),
    colorbar = (; label = "Amplitude (μV)"),
)

save(output_file, figure)
println("Saved topoplot to: $output_file")
display(figure)

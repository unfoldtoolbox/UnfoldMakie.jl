using UnfoldMakie
using Documenter
using DocStringExtensions

# preload once

using CairoMakie
const Makie = CairoMakie # - for references
using AlgebraOfGraphics
using Unfold
using DataFrames
using DataFramesMeta
using Literate
using Glob

GENERATED = joinpath(@__DIR__, "src", "generated")
SOURCE = joinpath(@__DIR__, "literate")
for subfolder ∈ ["how_to", "intro", "tutorials", "explanations"]
    local SOURCE_FILES = Glob.glob(subfolder * "/*.jl", SOURCE)
    foreach(fn -> Literate.markdown(fn, GENERATED * "/" * subfolder), SOURCE_FILES)
end

DocMeta.setdocmeta!(UnfoldMakie, :DocTestSetup, :(using UnfoldMakie); recursive = true)

makedocs(;
    modules = [UnfoldMakie],
    authors = "Vladimir Mikheev, Sören Döring, Niklas Gärtner, Daniel Baumgartner, Benedikt Ehinger",
    repo = Documenter.Remotes.GitHub("unfoldtoolbox", "UnfoldMakie.jl"),
    sitename = "UnfoldMakie.jl",
    warnonly = :cross_references,
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://unfoldtoolbox.github.io/UnfoldMakie.jl",
        assets = String[],
        sidebar_sitename = false,
    ),
    pages = [
        "Home" => "index.md",
        "Installing Julia & UnfoldMakie.jl" => "generated/explanations/installation.md",
        "Tutorials" => [
            "ERP Visualizations" => [
                "ERP plot" => "generated/tutorials/erp.md",
                "Butterfly plot" => "generated/tutorials/butterfly.md",
                "Topoplot" => "generated/tutorials/topoplot.md",
                "Topoplot series" => "generated/tutorials/topoplotseries.md",
                "ERP grid" => "generated/tutorials/erp_grid.md",
                "ERP image" => "generated/tutorials/erpimage.md",
                "Channel image" => "generated/tutorials/channel_image.md",
                "Parallel coordinates" => "generated/tutorials/parallelcoordinates.md",
                "Circular topoplots" => "generated/tutorials/circ_topo.md",
            ],
            "Unfold-specific Visualisations" => [
                "Design matrix" => "generated/tutorials/designmatrix.md",
                "Spline plot" => "generated/tutorials/splines.md",
            ],
            "Videos" => "generated/tutorials/videos.md",
        ],
        "How To Do" => [
            "Complex figures" => "generated/how_to/complex_figures.md",
            #"Channel labels" => "generated/how_to/topo_labels.md",
            "Hide decorations and axis spines" => "generated/how_to/hide_deco.md",
            "Colormap of butterfly plot" => "generated/how_to/position2color.md",
            "Uncertainty in topoplots" => "generated/how_to/uncertain_topo.md",
            "Electrode positions from 3D to 2D" => "generated/how_to/positions.md",
        ],
        "Explanations" => [
            "Plot types" => "generated/explanations/plot_types.md",
            "Key features" => "generated/explanations/key_features.md",
            "Code principles" => "generated/explanations/code_principles.md",
        ],
        "Reference" => [
            "Benchmarks" => "generated/explanations/speed.md",
            "API: Functions" => "api.md",
            "API: Utilities" => "helper.md",
        ],
    ],
)

deploydocs(;
    repo = "github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch = "main",
    push_preview = true,
)

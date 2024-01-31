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
for subfolder ∈ ["how_to", "intro", "tutorials", "reference"]
    local SOURCE_FILES = Glob.glob(subfolder * "/*.jl", SOURCE)
    foreach(fn -> Literate.markdown(fn, GENERATED * "/" * subfolder), SOURCE_FILES)
end

DocMeta.setdocmeta!(UnfoldMakie, :DocTestSetup, :(using UnfoldMakie); recursive = true)

makedocs(;
    modules = [UnfoldMakie],
    authors = "Vladimir Mikheev, Sören Döring, Niklas Gärtner, Daniel Baumgartner, Benedikt Ehinger",
    repo = "https://github.com/unfoldtoolbox/UnfoldMakie.jl/blob/{commit}{path}#{line}",
    sitename = "UnfoldMakie.jl",
    warnonly = :cross_references,
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://unfoldtoolbox.github.io/UnfoldMakie.jl",
        assets = String[],
    ),
    pages = [
        "UnfoldMakie Documentation" => "index.md",
        "Intro" => [
            "Installations" => "generated/intro/installation.md",
            "Plot Types" => "generated/intro/plot_types.md",
        ],
        "Visualization Types" => [
            "ERP plot" => "generated/tutorials/erp.md",
            "Butterfly Plot" => "generated/tutorials/butterfly.md",
            "Designmatrix" => "generated/tutorials/designmatrix.md",
            "ERP Image" => "generated/tutorials/erpimage.md",
            "Parallel Coordinates Plot" => "generated/tutorials/parallelcoordinates.md",
            "Topo Plot" => "generated/tutorials/topoplot.md",
            "Topo Plot Series" => "generated/tutorials/topoplotseries.md",
            "Circular TopoPlot" => "generated/tutorials/circ_topo.md",
        ],
        "How To" => [
            "Change Butterfly Colormap" => "generated/how_to/position2color.md",
            "Hide Axis Spines and Decorations" => "generated/how_to/hide_deco.md",
            "Include multiple Visualizations in one Figure" => "generated/how_to/mult_vis_in_fig.md",
        ],
        "Reference" => [
            "Convert 3D positions / montages to 2D layouts" => "generated/reference/positions.md",
        ],
        "API" => "api.md",
        "Utilities" => "helper.md",
    ],
)

deploydocs(;
    repo = "github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch = "main",
    push_preview = true,
)

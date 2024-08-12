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
    ),
    pages = [
        "UnfoldMakie Documentation" => "index.md",
        "Intro" => [
            "Installation" => "generated/intro/installation.md",
            "Plot types" => "generated/intro/plot_types.md",
            "Code principles" => "generated/intro/code_principles.md",
        ],
        "Visualization Types" => [
            "ERP plot" => "generated/tutorials/erp.md",
            "Butterfly plot" => "generated/tutorials/butterfly.md",
            "Topoplot" => "generated/tutorials/topoplot.md",
            "Topoplot series" => "generated/tutorials/topoplotseries.md",
            "ERP grid" => "generated/tutorials/erp_grid.md",
            "ERP image" => "generated/tutorials/erpimage.md",
            "Channel image" => "generated/tutorials/channel_image.md",
            "Parallel coordinates" => "generated/tutorials/parallelcoordinates.md",
            "Design matrix" => "generated/tutorials/designmatrix.md",
            "Circular topoplots" => "generated/tutorials/circ_topo.md",
        ],
        "How To" => [
            "Change colormap of Butterfly plot" => "generated/how_to/position2color.md",
            "Hide decorations and axis spines" => "generated/how_to/hide_deco.md",
            "Include multiple figures in one" => "generated/how_to/mult_vis_in_fig.md",
        ],
        "Explanations" => [
            "Convert electrode positions from 3D to 2D" => "generated/explanations/positions.md",
        ],
        "API / DocStrings" => "api.md",
        "Utilities" => "helper.md",
    ],
)

deploydocs(;
    repo = "github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch = "main",
    versions = "v#.#",
    push_preview = true,
)

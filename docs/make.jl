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
for subfolder ∈ ["explanations", "HowTo", "tutorials", "reference"]
    local SOURCE_FILES = Glob.glob(subfolder * "/*.jl", SOURCE)
    foreach(fn -> Literate.markdown(fn, GENERATED * "/" * subfolder), SOURCE_FILES)

end

DocMeta.setdocmeta!(UnfoldMakie, :DocTestSetup, :(using UnfoldMakie); recursive=true)

makedocs(;
    modules=[UnfoldMakie],
    authors="Benedikt Ehinger, Vladimir Mikheev, Daniel Baumgartner, Niklas Gärtner, Sören Döring",
    repo="https://github.com/unfoldtoolbox/UnfoldMakie.jl/blob/{commit}{path}#{line}",
    sitename="UnfoldMakie.jl",
    warnonly =  :cross_references,
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://unfoldtoolbox.github.io/UnfoldMakie.jl",
        assets=String[]
    ),
    pages=[
        "UnfoldMakie Documentation" => "index.md",
        "Visualizations-Types" => [
            "ERP plot" => "generated/tutorials/erp.md",
            "Butterfly Plot" => "tutorials/butterfly.md",
            "Designmatrix" => "tutorials/designmatrix.md",
            "ERP Image" => "tutorials/erpimage.md",
            "Parallel Coordinates Plot" => "tutorials/parallelcoordinates.md",
            "Topo Plot" => "tutorials/topoplot.md",
            "Topo Plot Series" => "tutorials/topoplotseries.md",
            "Circular TopoPlot" => "generated/tutorials/circTopo.md",
        ],
        "How To" => [
            "Butterfly Colormap" => "how_to/position2color.md",
            "Fix Parallel Coordinates Plot" => "how_to/fix_pcp.md",
            "Hide Axis Spines and Decorations" => "how_to/hide_deco.md",
            "Include multiple Visualizations in one Figure" => "how_to/mult_vis_in_fig.md",
            "Show out of Bounds Label" => "how_to/show_oob_labels.md",
        ],
        "Reference" => [
            "Convert 3D positions / montages to 2D layouts" => "generated/reference/positions.md"

        ],
        "API" => "api.md",
        "Utilities" => "helper.md",
    ],

)

deploydocs(;
    repo="github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch="main"
)

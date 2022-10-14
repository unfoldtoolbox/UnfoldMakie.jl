using UnfoldMakie
using Documenter
using DocStringExtensions

using Literate
using Glob

# literate
GENERATED = joinpath(@__DIR__, "src")
SOURCE_FILES = Glob.glob("*/*.jl", GENERATED)
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)



DocMeta.setdocmeta!(UnfoldMakie, :DocTestSetup, :(using UnfoldMakie); recursive=true)

makedocs(;
    modules=[UnfoldMakie],
    authors="Benedikt Ehinger, Daniel Baumgartner, Niklas Gärtner, Sören Döring",
    repo="https://github.com/unfoldtoolbox/UnfoldMakie.jl/blob/{commit}{path}#{line}",
    sitename="UnfoldMakie.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://unfoldtoolbox.github.io/UnfoldMakie.jl",
        assets=String[],
    ),
    pages=[
        "UnfoldMakie Documentation" => "index.md",
        "Tutorials: Setup" => [
            "Installation" => "tutorials/installation.md",
            "Test Data" => "tutorials/test_data.md",
        ],
        "Tutorials: Visualizations" => [
            "Butterfly Plot" => "tutorials/butterfly_plot.md",
            "Designmatrix" => "tutorials/design_matrix.md",
            "ERP Image" => "tutorials/erp_image.md",
            "Line Plot" => "tutorials/line_plot.md",
            "Parallel Coordinates Plot" => "tutorials/para_coord.md",
            "Topo Plot" => "tutorials/topo_plot.md",
        ],
        "Plot Configuration" => [
            "Axis Data" => "config/axis_data.md",
            "Colorbar Data" => "config/colorbar_data.md",
            "Extra Data" => "config/extra_data.md",
            "Layout Data" => "config/layout_data.md",
            "Legend Data" => "config/legend_data.md",
            "Mapping Data" => "config/mapping_data.md",
            "Visual Data" => "config/visual_data.md",
        ],
        "How To" => [
            "Fix Parallel Coordinates Plot" => "how_to/fix_pcp.md",
            "Generate a Timeexpanded Designmatrix" => "how_to/gen_te_designmatrix.md",
            "Hide Axis Spines and Decorations" => "how_to/hide_deco.md",
            "Include multiple Visualizations in one Figure" => "how_to/mult_vis_in_fig.md",
            "Show out of Bounds Label" => "how_to/show_oob_labels.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch="main",
)

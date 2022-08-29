using UnfoldMakie
using Documenter

using Literate
using Glob

# literate
GENERATED = joinpath(@__DIR__, "src")
SOURCE_FILES = Glob.glob("*/*.jl", GENERATED)
foreach(fn -> Literate.markdown(fn, GENERATED), SOURCE_FILES)



DocMeta.setdocmeta!(UnfoldMakie, :DocTestSetup, :(using UnfoldMakie); recursive=true)

makedocs(;
    modules=[UnfoldMakie],
    authors="Benedikt Ehinger",
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
        "Tutorials: General Visualizations" => [
            "Butterfly Plot" => "tutorials/butterfly_plot.md",
            "Designmatrix" => "tutorials/design_matrix.md",
            "ERP Image" => "tutorials/erp_image.md",
            "Line Plot" => "tutorials/line_plot.md",
            "Parallel Coordinates Plot" => "tutorials/para_coord.md",
            "Topo Plot" => "tutorials/topo_plot.md",
        ],
        "Plot Configuration" => [
            "Overview" => "config/plot_config.md",
            "Config Colorbar Data" => "config/colorbar_data.md",
            "Config Extra Data" => "config/extra_data.md",
            "Config Layout Data" => "config/layout_data.md",
            "Config Legend Data" => "config/legend_data.md",
            "Config Mapping Data" => "config/mapping_data.md",
            "Config Visual Data" => "config/visual_data.md",
        ],
        "Visualization Options" => [
            "For Butterfly Plot" => "vis_options/o_butterfly_plot.md",
            "For Designmatrix" => "vis_options/o_design_matrix.md",
            "For ERP Image" => "vis_options/o_erp_image.md",
            "For Line Plot" => "vis_options/o_line_plot.md",
            "For Parallel Coordinates Plot" => "vis_options/o_para_coord.md",
            "For Topo Plot" => "vis_options/o_topo_plot.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch="main",
)

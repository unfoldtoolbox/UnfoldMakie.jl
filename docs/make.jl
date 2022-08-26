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
        "Home" => "index.md",
        "Installation" => "tutorials/installation.md",
        "Test Data" => "tutorials/test_data.md",
        "Butterfly Plot" => "tutorials/butterfly_plot.md",
        "Designmatrix" => "tutorials/design_matrix.md",
        "ERP Image" => "tutorials/erp_image.md",
        "Line Plot" => "tutorials/line_plot.md",
        "Parallel Coordinates Plot" => "tutorials/para_coord.md",
        "Topo Plot" => "tutorials/topo_plot.md",
        "Plot Configuration" => "config/plot_config.md",
        "Config Colorbar Data" => "config/colorbar_data.md",
        "Config Extra Data" => "config/extra_data.md",
        "Config Layout Data" => "config/layout_data.md",
        "Config Legend Data" => "config/legend_data.md",
        "Config Mapping Data" => "config/mapping_data.md",
        "Config Visual Data" => "config/visual_data.md",
    ],
)

deploydocs(;
    repo="github.com/unfoldtoolbox/UnfoldMakie.jl",
    devbranch="main",
)

using LiveServer
servedocs(
    skip_dir = joinpath("src", "generated"),
    literate_dir = joinpath("literate"),
    literate = joinpath("literate"),
    foldername = ".",
)

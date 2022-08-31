# [Installation](@id install_instruct)

## Getting Julia

You can install Julia by following the instructions from the [official website](https://julialang.org/). 

## Setup UnfoldMakie.jl

After installing Julia, you can execute the `julia.exe`. 

## Generate a Project

If you do not yet have a project you can generate one. 
First you type `]` into the Julia console to switch from `julia` to `(@VERSION) pkg`. 
Here you can generate a project by using the command: 

```
generate "FOLDER_PATH"
```

Use backslash `\` for the folder path. 
Note that the specific folder in which you want to generate the project does not already exist.

## Activate your Project

Before you can add the necessary modules to use UnfoldMakie you have to activate your project in the `(@VERSION) pkg` environment. 
The command is: 

```
activate "FOLDER_PATH"
```

Use backslash `\` for the folder path. 

## Install the UnfoldMakie Module

When your project is activated you can add the module. 
The command is: 

```
add UnfoldMakie
```

## Using the Project in a Notebook

In case you want to use this generated project in a notebook (e.g. [Pluto](https://www.juliapackages.com/p/pluto) or [Jupyter](https://ipython.org/notebook.html)), you can activate this in the notebook in the following manner:
```
begin
    using Pkg
    Pkg.activate("FOLDER_PATH")
    Pkg.resolve()
end
```
Use slash `/` for the folder path. 

## TODO: INSTRUCTIONS

Add missing "documentation environment"?
https://github.com/unfoldtoolbox/Unfold.jl/blob/main/docs/src/tutorials/installation.md
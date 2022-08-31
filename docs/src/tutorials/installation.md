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

## Install a dev-version of UnfoldMakie
In order to see and change the tutorials, you have to install a local dev-version of UnfoldMakie via:
`]dev --local UnfoldMakie` - which installs it in `./dev/UnfoldMakie`

## Instantiating the documentation environment
- Now we have to add the packages required for the documentation.
- Next we have to make sure to be in the `UnfoldMakie/docs` folder, else the tutorial will not be able to find the data. Thus `cd("./docs")` in case you cd'ed already to the UnfoldMakie project. 
- And the `]activate .` to activate the docs-environment.
- Finally run `]instantiate` to install the required packages. Now you are ready to run the tutorials locally

## [Installation](@id install_instruct)

### Getting Julia

You can install Julia by following the instructions from the [official website](https://julialang.org/). 

### Setup UnfoldMakie.jl

After installing Julia, you can execute the `julia.exe`. 

### Generate a project

If you do not yet have a project you can generate one. 
First you type `]` into the Julia console to switch from `julia` to `(@VERSION) pkg`. 
Here you can generate a project by using the command: 

```
generate "FOLDER_PATH"
```

Use `\` for the folder path. 

### Activate your project

Before you can add the necessary modules to use UnfoldMakie you have to activate your project in the `(@VERSION) pkg` environment. 
The command is: 

```
activate "FOLDER_PATH"
```

Use `\` for the folder path. 

### Install our module

When your project is activated you can add the module. 
The command is: 

```
add UnfoldMakie
```

## TODO INSTRUCTIONS

Add missing "documentation environment"
https://github.com/unfoldtoolbox/Unfold.jl/blob/main/docs/src/tutorials/installation.md
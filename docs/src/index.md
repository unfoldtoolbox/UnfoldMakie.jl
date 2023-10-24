# UnfoldMakie Documentation


This is the documentation of the UnfoldMakie module for the Julia programming language. 

## About

UnfoldMakie aims to allow users to generate different types of visualizations. 
These include line plots, butterfly plots, designmatrices, parallel coordinates plots, ERP images and topo plots.
Building on the [Unfold](https://github.com/unfoldtoolbox/unfold.jl/) and [Makie](https://makie.juliaplots.org/stable/) Modules, it also grants users customizability through an input configuration on the plots.

As is apparent considering the types of possible visualizations, these config options try to enable users to create plots, that are helpful in the subject area of computational EEG.
One such example is the possibility of using a topo plot as a legend for a line plot by allowing for multiple visualizations within one figure.

![Coordinated Multiple Views](./images/every_plot.png)

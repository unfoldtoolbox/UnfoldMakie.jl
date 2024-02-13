# If you want to efficiently hide decorations and axis spines in in a plot you have several options to do it.
# # Package input

using TopoPlots
using UnfoldMakie
using CairoMakie
using DataFrames

include("../../../example_data.jl")
data, pos = example_data("TopoPlots.jl")

#=
First, you can specify the axis settings with `axis=(; ...)`. 
Makie.Axis` provides multiple variables for different aspects of the plot. This means that removing all decorations is only possible by setting many variables each time.

Second, `Makie` does provide methods like `hidespines!` and `hidedecorations!`. Unforunately, user may lose access to a plot after it is drawn in.

Third, `hidespines!` and `hidedecorations!` can be called by setting variables with `layout = (; hidespines = (), hidedecorations = ())`.

Same with spines: `hidespines = (:r, :t)` will remove the top and right borders.
=#


f = Figure()
plot_butterfly!(
    f[1, 1],
    data;
    positions = pos,
    topomarkersize = 10,
    topoheigth = 0.4,
    topowidth = 0.4,
)
plot_butterfly!(
    f[2, 1],
    data;
    positions = pos,
    topomarkersize = 10,
    topoheigth = 0.4,
    topowidth = 0.4,
    layout = (; hidedecorations = (:label => true, :ticks => true, :ticklabels => true)),
)
for (label, layout) in zip(["with decorations", "without"], [f[1, 1], f[2, 1]])
    Label(
        layout[1, 1, TopLeft()],
        label,
        fontsize = 26,
        font = :bold,
        padding = (0, -250, 25, 0),
        halign = :left,
    )
end
f

#=
Since some plots hide features by default, which can be reverted by setting the variables to `nothing`
=#

data, positions = TopoPlots.example_data()
plot_topoplot(
    data[:, 340, 1];
    positions = positions,
    layout = (; hidespines = nothing, hidedecorations = nothing),
)

# For more information on the input of these functions refer to the [Makie dokumentation on Axis.](https://makie.juliaplots.org/v0.15.2/examples/layoutables/axis/#hiding_axis_spines_and_decorations)

using Makie

"""
    plot_parallelcoordinates(data::Union{DataFrame, AbstractMatrix}; kwargs...)
    plot_parallelcoordinates!(f::Union{GridPosition, GridLayout, Figure}, data::Union{DataFrame, AbstractMatrix}; kwargs)
    

Plot a PCP (parallel coordinates plot).\\
Dimensions: conditions, channels, time, trials. 
 
## Arguments:
- `f::Union{GridPosition, GridLayout, Figure}`
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, AbstractMatrix}`\\
    Data for the plot visualization.

## Keyword arguments (kwargs)
- `normalize::Symbol = nothing`\\
    If `:minmax`, normalize each axis to their respective min-max range.
- `ax_labels::Vector{String} = nothing`\\
    Specify axis labels. \\
    Should be a vector of labels with length equal to the number of unique `mapping.x` values.\\
    Example: `ax_labels = ["Fz", "Cz", "O1", "O2"]`.
- `ax_ticklabels::Symbol = :outmost`\\
    Specify tick labels on axis.
    - `:all` - show all labels on all axes.
    - `:left` - show all labels on the left axis, but only min and max on others. 
    - `:outmost` - show labels on min and max of all other axes. 
    - `:none` - remove all labels. 
- `bend::Bool = false`\\
    Change straight lines between the axes to curved ("bent") lines using spline interpolation.\\
    Note: While this makes the plot look cool, it is not generally recommended to bent the lines, as interpretation
    suffers, and the resulting visualizations can be potentially missleading.
- `visual.alpha::Number = 0.5`\\
    Change of line transparency.

## Defining the axes
- `mapping.x = :channel, mapping.y = :estimate`.\\
    Overwrite what should be on the x and the y axes.
- `mapping.color = :colorcolumn` \\
    Split conditions by color. The default color is `:black`.

$(_docstring(:paracoord))

**Return Value:** `Figure` displaying the Parallel coordinates plot.
"""
plot_parallelcoordinates(data::Union{DataFrame,AbstractMatrix}; kwargs...) =
    plot_parallelcoordinates(Figure(), data; kwargs...)

function plot_parallelcoordinates(
    f,
    data::Union{DataFrame,AbstractMatrix};
    ax_ticklabels = :outmost,
    ax_labels = nothing,
    normalize = nothing,
    bend = false,
    kwargs...,
)
    if isa(data, AbstractMatrix{<:Real})
        data = eeg_array_to_dataframe(data)
    end
    config = PlotConfig(:paracoord)
    UnfoldMakie.config_kwargs!(config; kwargs...)

    config.mapping = UnfoldMakie.resolve_mappings(data, config.mapping)

    # remove all unspecified columns
    d = select(data, config.mapping...)

    # stack the data to a matrix-like (still list of list of lists!)
    d2 = unstack(
        d,
        Not(config.mapping.x, config.mapping.y),
        config.mapping.x,
        config.mapping.y,
        combine = copy,
    )
    # remove the non x/y columns, we want a matrix at the end
    rm_col =
        filter(x -> x != config.mapping.x && x != config.mapping.y, [config.mapping...])
    d3 = select(d2, Not(rm_col))

    # give use list of matrix
    d4 = reduce.(hcat, eachrow(Array(d3)))

    # give us a single matrix
    d5 = reduce(vcat, d4)'

    # figure out the color vector
    if :color ∈ keys(config.mapping)
        c_split = map((c, n) -> repeat([c], n), d2[:, config.mapping.color], size.(d4, 1))
        c = vcat(c_split...)
        line_labels = string.(c)
    else
        c = config.visual.color
        line_labels = nothing
        if config.layout.show_legend
            @warn "Disable legend because there was no color choice"
            UnfoldMakie.config_kwargs!(config; layout = (; show_legend = false))
        end
    end
    UnfoldMakie.config_kwargs!(config; visual = (; color = c))

    outer_axis = Axis(f[1, 1]; config.axis...)
    outer_axis.title = "" # we dont want a title here
    f1, outer_axis, axlist, hlines = parallel_coordinates(
        f, outer_axis,
        d5;
        normalize = normalize,
        color = c,
        bend = bend,
        line_labels = line_labels,
        ax_labels = ax_labels,
        ax_ticklabels = ax_ticklabels,
    )
    Label(
        f[1, 1, Top()],
        text = config.axis.title,
        padding = (20, 20, 22, 0),
        fontsize = 20,
        font = :bold,
    )
    if config.layout.show_legend
        Legend(f[1, 2], outer_axis, config.legend.title; config.legend...)
    end
    apply_layout_settings!(config; fig = f1, ax = outer_axis)
    res =
        isa(f, Figure) ? Makie.FigureAxisPlot(f, [outer_axis, axlist], hlines[1]) :
        Makie.AxisPlot([outer_axis, axlist], hlines[1])
    return res
end

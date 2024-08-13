using DataFrames
using TopoPlots
using LinearAlgebra
"""
    plot_butterfly(plot_data::Union{DataFrame, AbstractMatrix}; kwargs...)
    plot_butterfly(times::Vector, plot_data::Union{DataFrame, AbstractMatrix}; kwargs...)
    plot_butterfly!(f::Union{GridPosition, GridLayout, Figure}, plot_data::Union{DataFrame, AbstractMatrix}; kwargs...)

Plot a Butterfly plot.

## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{DataFrame, AbstractMatrix}`\\
    Data for the ERP plot visualization.
- `kwargs...`\\
    Additional styling behavior. \\
    Often used as: `plot_butterfly(df; visual = (; colormap = :romaO))`.

## Keyword argumets (kwargs)
- `positions::Array = []` \\
    Adds a topoplot as an inset legend to the provided channel positions. Must be the same length as `plot_data`.  
    To change the colors of the channel lines use the `topoposition_to_color` function.
- `topolegend::Bool = true`\\
    Show an inlay topoplot with corresponding electrodes. Requires `positions`.
- `topomarkersize::Real = 10` \\
    Change the size of the electrode markers in topoplot.
- `topowidth::Real = 0.25` \\
    Change the width of inlay topoplot.
- `topoheight::Real = 0.25` \\
    Change the height of inlay topoplot.
- `topopositions_to_color::x -> pos_to_color_RomaO(x)`\\
    Change the line colors.

**Return Value:** `Figure` displaying Butterfly plot.

$(_docstring(:butterfly))
see also [`plot_erp`](@ref erp_vis)
"""
plot_butterfly(plot_data::Union{<:AbstractDataFrame,AbstractMatrix}; kwargs...) =
    plot_butterfly!(Figure(), plot_data; kwargs...)

function plot_butterfly!(
    f::Union{GridPosition,GridLayout,<:Figure},
    plot_data::Union{<:AbstractDataFrame,AbstractMatrix};
    positions = nothing,
    labels = nothing,
    topolegend = true,
    topomarkersize = 10,
    topowidth = 0.35,
    topoheight = 0.35,
    topohalign = 0.05,
    topovalign = 0.95,
    topoaspect = 1,
    topopositions_to_color = x -> pos_to_color_RomaO(x),
    mapping = (;),
    kwargs...,
)

    config = PlotConfig(:butterfly)
    config_kwargs!(config; mapping, kwargs...)
    plot_data = deepcopy(plot_data) # to avoid change of data in REPL
    if isa(plot_data, AbstractMatrix{<:Real})
        plot_data = eeg_array_to_dataframe(plot_data)
        config_kwargs!(config; axis = (; xlabel = "Time [samples]"))
    end
    # resolve columns with data
    config.mapping = resolve_mappings(plot_data, config.mapping)

    #remove mapping values with `nothing`
    deleteKeys(nt::NamedTuple{names}, keys) where {names} =
        NamedTuple{filter(x -> x ∉ keys, names)}(nt)
    config.mapping = deleteKeys(
        config.mapping,
        keys(config.mapping)[findall(isnothing.(values(config.mapping)))],
    )
    # turn "nothing" from group columns into :fixef
    if "group" ∈ names(plot_data)
        plot_data.group = plot_data.group .|> a -> isnothing(a) ? :fixef : a
    end

    if isnothing(positions) && isnothing(labels)
        topolegend = false
        colors = nothing
    else
        all_positions = get_topo_positions(; positions = positions, labels = labels)
        if (config.visual.colormap !== nothing)
            colors = config.visual.colormap
            un = length(unique(plot_data[:, config.mapping.color]))
            colors = cgrad(config.visual.colormap, un, categorical = true)
        else
            colors = get_topo_color(all_positions, topopositions_to_color)
        end
    end
    # Categorical mapping
    # convert color column into string to prevent wrong grouping
    if (:group ∈ keys(config.mapping))
        config.mapping =
            merge(config.mapping, (; group = config.mapping.group => nonnumeric))
    end
    if (:color ∈ keys(config.mapping))
        config.mapping =
            merge(config.mapping, (; color = config.mapping.color => nonnumeric))
    end
    if (
        :col ∈ keys(config.mapping) &&
        typeof(plot_data[:, config.mapping.col]) == Vector{Int64}
    )
        config.mapping = merge(config.mapping, (; col = config.mapping.col => nonnumeric))
    end

    mapp = AlgebraOfGraphics.mapping()

    if (:color ∈ keys(config.mapping))
        mapp = mapp * AlgebraOfGraphics.mapping(; config.mapping.color)
    end

    if (:group ∈ keys(config.mapping))
        mapp = mapp * AlgebraOfGraphics.mapping(; config.mapping.group)
    end

    # remove x / y
    mapping_others = deleteKeys(config.mapping, [:x, :y, :positions, :lables])
    xy_mapp =
        AlgebraOfGraphics.mapping(config.mapping.x, config.mapping.y; mapping_others...)
    basic = visual(Lines; config.visual...) * xy_mapp
    basic = basic * data(plot_data)
    plot_equation = basic * mapp

    f_grid = f[1, 1]

    if (topolegend)
        topoAxis = Axis(
            f_grid,
            width = Relative(topowidth),
            height = Relative(topoheight),
            halign = topohalign,
            valign = topovalign,
            aspect = topoaspect,
        )
        ix = unique(i -> plot_data[:, config.mapping.group[1]][i], 1:size(plot_data, 1))

        topoplot_legend(
            topoAxis,
            topomarkersize,
            plot_data[ix, config.mapping.color[1]],
            colors,
            all_positions,
        )
    end

    if isnothing(colors)
        drawing = draw!(f_grid, plot_equation; axis = config.axis)
    else
        drawing = draw!(
            f_grid,
            plot_equation,
            scales(Color = (; palette = colors));
            axis = config.axis,
        )
    end
    apply_layout_settings!(config; fig = f, ax = drawing, drawing = drawing)
    return f
end

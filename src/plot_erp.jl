using DataFrames
using TopoPlots
using LinearAlgebra
"""
    plot_erp!(f::Union{GridPosition, GridLayout, Figure}, plot_data::DataFrame; kwargs...)
    plot_erp(times, plot_data::Union{AbstractMatrix,AbstractVector{<:Number}}; kwargs...)
    plot_erp(plot_data::Union{DataFrame, <:AbstractMatrix, <:AbstractVector}; kwargs...) 
        
Plot an ERP plot.   

## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{Union{DataFrame, AbstractMatrix, AbstractVector{<:Number}, Vector{Float32}}`\\
    Data for the ERP plot visualization.
- `kwargs...`\\
    Additional styling behavior. \\
    Often used as: `plot_erp(df; mapping = (; color = :coefname, col = :conditionA))`.

## Keyword argumets (kwargs)

- `categorical_color::Bool = true`\\
    Treat `:color` as categorical variable in case of numeric `:color` column.
- `categorical_group::Bool = true`\\
    Treat `:group` as categorical variable in case of numeric `:group` column. 
- `stderror::Bool = false`\\
    Add an error ribbon, with lower and upper limits based on the `:stderror` column.
- `significance::DataFrame = nothing`\\
    Show significant time periods as horizontal bars.\\
    Example: `DataFrame(from = [0.1, 0.3], to = [0.5, 0.7], coefname = ["(Intercept)", "condition: face"])`.\\
    If `coefname` is not specified, the significance lines will be black.
- `layout.use_colorbar = true`\\
    Enable or disable colorbar.\\
- `layout.use_legend = true`\\
    Enable or disable legend.\\
- `layout.show_legend = true`\\
    Enable or disable legend and colorbar.\\

$(_docstring(:erp))

**Return Value:** `Figure` displaying the ERP plot.

"""
plot_erp(plot_data::DataFrame; kwargs...) = plot_erp!(Figure(), plot_data; kwargs...)

plot_erp(plot_data::Union{AbstractMatrix,AbstractVector{<:Number}}; kwargs...) = plot_erp(
    eeg_array_to_dataframe(plot_data');
    axis = (; xlabel = "Time [samples]"),
    kwargs...,
)

plot_erp(times, plot_data::Union{AbstractMatrix,AbstractVector{<:Number}}; kwargs...) =
    plot_erp(eeg_array_to_dataframe(plot_data'); axis = (; xticks = times), kwargs...)

function plot_erp!(
    f::Union{GridPosition,GridLayout,Figure},
    plot_data::DataFrame;
    positions = nothing,
    labels = nothing,
    categorical_color = true,
    categorical_group = true,
    stderror = false, # XXX if it exists, should be plotted
    significance = nothing,
    mapping = (;),
    kwargs...,
)
    config = PlotConfig(:erp)
    config_kwargs!(config; mapping, kwargs...)
    plot_data = deepcopy(plot_data)

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

    # check if stderror values exist and create new columns with high and low band
    if "stderror" ∈ names(plot_data) && stderror
        plot_data.stderror = plot_data.stderror .|> a -> isnothing(a) ? 0.0 : a
        plot_data[!, :se_low] = plot_data[:, config.mapping.y] .- plot_data.stderror
        plot_data[!, :se_high] = plot_data[:, config.mapping.y] .+ plot_data.stderror
    end
    # Categorical mapping
    # convert color column into string to prevent wrong grouping
    if categorical_color && (:color ∈ keys(config.mapping))
        config.mapping =
            merge(config.mapping, (; color = config.mapping.color => nonnumeric))
    end

    # converts group column into string
    if categorical_group && (:group ∈ keys(config.mapping))
        config.mapping =
            merge(config.mapping, (; group = config.mapping.group => nonnumeric))
    end
    if (
        :col ∈ keys(config.mapping) &&
        typeof(plot_data[:, config.mapping.col]) <: AbstractVector{<:Number}
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
    # add band of sdterrors
    if stderror
        m_se = AlgebraOfGraphics.mapping(config.mapping.x, :se_low, :se_high)
        basic = basic + visual(Band, alpha = 0.5) * m_se
    end

    basic = basic * data(plot_data)

    # add the p-values
    if !isnothing(significance)
        basic = basic + add_significance(plot_data, significance, config)
    end

    plot_equation = basic * mapp

    f_grid = f[1, 1:4]

    # draw a normal ERP lineplot  
    drawing = draw!(f_grid, plot_equation; axis = config.axis)
    if config.layout.show_legend == true
        config_kwargs!(config; mapping, layout = (; show_legend = false))
        if config.layout.use_legend == true
            legend!(f[:, 5], drawing; config.legend...)
        end
        if config.layout.use_colorbar == true
            N = config.layout.use_legend == false ? 5 : 6
            colorbar!(f[:, N], drawing; config.colorbar...)
        end
    end
    apply_layout_settings!(config; fig = f, ax = drawing, drawing = drawing)
    return f
end

function eeg_head_matrix(positions, center, radius)
    oldCenter = mean(positions)
    oldRadius, _ = findmax(x -> norm(x .- oldCenter), positions)
    radF = radius / oldRadius
    return Makie.Mat4f(
        radF,
        0,
        0,
        0,
        0,
        radF,
        0,
        0,
        0,
        0,
        1,
        0,
        center[1] - oldCenter[1] * radF,
        center[2] - oldCenter[2] * radF,
        0,
        1,
    )
end

# topopositions_to_color = colors?
function topoplot_legend(axis, topomarkersize, unique_val, colors, all_positions)
    all_positions = unique(all_positions)

    topo_matrix = eeg_head_matrix(all_positions, (0.5, 0.5), 0.5)

    un = unique(unique_val)
    special_colors =
        ColorScheme(vcat(RGB(1, 1, 1.0), colors[map(x -> findfirst(x .== un), unique_val)]))

    xlims!(low = -0.2, high = 1.2)
    ylims!(low = -0.2, high = 1.2)
    topoplot = eeg_topoplot!(
        axis,
        1:length(all_positions), # go from 1:npos
        string.(1:length(all_positions));
        positions = all_positions,
        interpolation = NullInterpolator(), # inteprolator that returns only 0, which is put to white in the special_colorsmap
        colorrange = (0, length(all_positions)), # add the 0 for the white-first color
        colormap = special_colors,
        head = (color = :black, linewidth = 1, model = topo_matrix),
        label_scatter = (markersize = topomarkersize, strokewidth = 0.5),
    )

    hidedecorations!(current_axis())
    hidespines!(current_axis())

    return topoplot
end

function add_significance(plot_data, significance, config)
    p = deepcopy(significance)

    # for now, add them to the fixed effect
    if "group" ∉ names(p)
        # group not specified using first
        if "group" ∈ names(plot_data)
            p[!, :group] .= plot_data[1, :group]
            if length(unique(plot_data.group)) > 1
                @warn "multiple groups found, choosing first one"
            end
        else
            p[!, :group] .= 1
        end
    end
    if :color ∈ keys(config.mapping)
        c = config.mapping.color isa Pair ? config.mapping.color[1] : config.mapping.color
        un = unique(p[!, c])
        p[!, :sigindex] .= [findfirst(un .== x) for x in p.coefname]
    else
        p[!, :signindex] .= 1
    end
    # define an index to dodge the lines vertically

    scaleY = [minimum(plot_data.estimate), maximum(plot_data.estimate)]
    stepY = scaleY[2] - scaleY[1]
    posY = stepY * -0.05 + scaleY[1]
    Δt = diff(plot_data.time[1:2])[1]
    Δy = 0.01
    p[!, :segments] = [
        Makie.Rect(
            Makie.Vec(x, posY + stepY * (Δy * (n - 1))),
            Makie.Vec(y - x + Δt, 0.5 * Δy * stepY),
        ) for (x, y, n) in zip(p.from, p.to, p.sigindex)
    ]
    res = data(p) * mapping(:segments) * visual(Poly)
    return (res)
end

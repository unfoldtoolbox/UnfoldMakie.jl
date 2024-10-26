using DataFrames
using TopoPlots
using LinearAlgebra
"""
    plot_erp!(f::Union{GridPosition, GridLayout, Figure}, plot_data::Union{DataFrame, AbstractMatrix, AbstractVector{<:Number}}; kwargs...)
    plot_erp(times, plot_data::Union{DataFrame, AbstractMatrix, AbstractVector{<:Number}}; kwargs...)

Plot an ERP plot.   

## Arguments

- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{Union{DataFrame, AbstractMatrix, AbstractVector{<:Number}, Vector{Float32}}`\\
    Data for the ERP plot visualization.
- `kwargs...`\\
    Additional styling behavior. \\
    Often used as: `plot_erp(df; mapping = (; color = :coefname, col = :conditionA))`.

## Keyword arguments (kwargs)

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
- `mapping = (;)`\\
    Specify `color`, `col` (column), `linestyle`, `group`.\\
    F.i. `mapping = (; col = :group)` will make a column for each group.
- `visual = (; color = Makie.wong_colors, colormap = :roma)`\\
    For categorical color use `visual.color`, for continuous - `visual.colormap`.\\

$(_docstring(:erp))

**Return Value:** `Figure` displaying the ERP plot.

"""
plot_erp(plot_data::Union{DataFrame,AbstractMatrix,AbstractVector{<:Number}}; kwargs...) =
    plot_erp!(Figure(), plot_data; kwargs...)

plot_erp(
    times,
    plot_data::Union{DataFrame,AbstractMatrix,AbstractVector{<:Number}};
    kwargs...,
) = plot_erp(plot_data; axis = (; xticks = times), kwargs...)

function plot_erp!(
    f::Union{GridPosition,GridLayout,Figure},
    plot_data::Union{DataFrame,AbstractMatrix,AbstractVector{<:Number}};
    positions = nothing,
    labels = nothing,
    categorical_color = nothing,
    categorical_group = nothing,
    stderror = false, # XXX if it exists, should be plotted
    significance = nothing,
    mapping = (;),
    kwargs...,
)
    if !(isnothing(categorical_color) && isnothing(categorical_group))
        @warn "categorical_color and categorical_group have been deprecated.
        To switch to categorical colors, please use `mapping(..., color = :mycolorcolum => nonnumeric)`.
        `group` is now automatically cast to nonnumeric."
    end
    config = PlotConfig(:erp)
    config_kwargs!(config; mapping, kwargs...)
    plot_data = deepcopy(plot_data)
    if isa(plot_data, Union{AbstractMatrix{<:Real},AbstractVector{<:Number}})
        plot_data = eeg_array_to_dataframe(plot_data')
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

    # automatically convert col & group to nonnumeric
    if (
        :col ∈ keys(config.mapping) &&
        !isa(config.mapping.col, Pair) &&
        typeof(plot_data[:, config.mapping.col]) <: AbstractVector{<:Number}
    )
        config.mapping = merge(config.mapping, (; col = config.mapping.col => nonnumeric))
    end

    if (
        :group ∈ keys(config.mapping) &&
        !isa(config.mapping.group, Pair) &&
        typeof(plot_data[:, config.mapping.group]) <: AbstractVector{<:Number}
    )
        config.mapping =
            merge(config.mapping, (; group = config.mapping.group => nonnumeric))
    end

    # check if stderror values exist and create new columns with high and low band
    if "stderror" ∈ names(plot_data) && stderror
        plot_data.stderror = plot_data.stderror .|> a -> isnothing(a) ? 0.0 : a
        plot_data[!, :se_low] = plot_data[:, config.mapping.y] .- plot_data.stderror
        plot_data[!, :se_high] = plot_data[:, config.mapping.y] .+ plot_data.stderror
    end

    mapp = AlgebraOfGraphics.mapping()

    # mapping for stderrors 
    for i in [:color, :group, :col, :row, :layout]
        if (i ∈ keys(config.mapping))
            tmp = getindex(config.mapping, i)
            mapp = mapp * AlgebraOfGraphics.mapping(; i => tmp)
        end
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

    f_grid = f[1, 1] = GridLayout()

    color_mapper =
        isa(config.mapping.color, Symbol) ? config.mapping.color : config.mapping.color[1]
    color_type = isa(config.mapping.color, Symbol) ? "nonnumeric" : config.mapping.color[2]

    scales_tmp = if !isa(plot_data[:, color_mapper][1], String) && color_type != nonnumeric
        (; colormap = config.visual.colormap) # for continuous
    else
        (; palette = config.visual.color) # for categorical
    end
    drawing = draw!(f_grid, plot_equation, scales(Color = scales_tmp); axis = config.axis)

    if config.layout.show_legend == true
        config_kwargs!(config; mapping, layout = (; show_legend = false))
        if config.layout.use_legend == true
            legend!(f_grid[:, end+1], drawing; config.legend...)
        end
        if config.layout.use_colorbar == true
            colorbar!(f_grid[:, end+1], drawing; config.colorbar...)
        end
    end
    apply_layout_settings!(config; fig = f, ax = drawing, drawing = drawing)
    return f
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

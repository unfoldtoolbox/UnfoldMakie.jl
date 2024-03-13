using DataFrames
using TopoPlots
using LinearAlgebra
"""
    plot_erp!(f::Union{GridPosition, GridLayout, Figure}, plot_data::DataFrame; kwargs...)
    plot_erp(plot_data::DataFrame; kwargs...)
        
Plot an ERP plot.   

## Arguments:

- `f::Union{GridPosition, GridLayout, Figure}`: Figure, GridLayout or GridPosition that the plot should be drawn into.
- `plot_data::DataFrame`: Data for the line plot visualization.
- `kwargs...`: Additional styling behavior. Often used: `plot_erp(df; mapping=(; color=:coefname, col=:conditionA))`.

## kwargs (...; ...):

- `categorical_color` (`bool`, default = `true`): in case of numeric `:color` column, treat `:color` as continuous or categorical variable.
- `categorical_group` (`bool`, default = `true`): in case of numeric `:group` column, treat `:group` as categorical variable by default.
- `stderror` (`bool`, default = `false`): add an error ribbon, with lower and upper limits based on the `:stderror` column.
- `pvalue` (`Array`, default = `[]`): show a pvalue.
    - example: `DataFrame(from = [0.1, 0.3], to=[0.5, 0.7], coefname=["(Intercept)", "condition:face"])` -  if coefname is not specified, the lines will be black.
- `positions` (`Array`, default = `[]`): see plot_butterfly.
- `topolegend` (`bool`, default = `false`): (see `plot_butterfly`).

Internal-use only:
- `butterfly` (`bool`, default = `true`): a butterfly plot instead of an ERP plot. See `plot_butterfly`

$(_docstring(:erp))

## Return Value:

- f - Figure() or the inputed `f`

"""
plot_erp(plot_data::DataFrame; kwargs...) = plot_erp!(Figure(), plot_data, ; kwargs...)

"""
    plot_butterfly(plot_data::DataFrame; positions = nothing)

Plot a Butterfly plot.

## kwargs (...; ...):
- `positions` (`Array`, default = `[]`): if specified, adds a topoplot as an inset legend to the provided channel positions. Must be the same length as `plot_data`.  
    To change the colors of the channel lines use the `topoposition_to_color` function.
- `topolegend` (`bool`, default = `true`): show an inlay topoplot with corresponding electrodes. Requires `positions` to be provided.
- `topomarkersize` (`Real`, default = `10`): change the size of the markers, topoplot-inlay electrodes.
- `topowidth` (`Real`, default = `0.25`): change the size of the inlay topoplot width.
- `topoheigth` (`Real`, default = `0.25`): change the size of the inlay topoplot height.
- `topopositions_to_color` (function, `x -> posToColorRomaO(x)`): change the colors of the channel lines.


$(_docstring(:butterfly))
see also [`plot_erp`](@id erp_vis)
"""
plot_butterfly(plot_data::DataFrame; kwargs...) =
    plot_butterfly!(Figure(), plot_data; kwargs...)

plot_butterfly!(
    f::Union{GridPosition,GridLayout,<:Figure},
    plot_data::DataFrame;
    kwargs...,
) = plot_erp!(
    f,
    plot_data;
    butterfly = true,
    topolegend = true,
    topomarkersize = 10,
    topowidth = 0.25,
    topoheigth = 0.25,
    topopositions_to_color = x -> posToColorRomaO(x),
    kwargs...,
)

function plot_erp!(
    f::Union{GridPosition,GridLayout,Figure},
    plot_data::DataFrame;
    positions = nothing,
    labels = nothing,
    categorical_color = true,
    categorical_group = true,
    stderror = false, # XXX if it exists, should be plotted
    pvalue = [],
    butterfly = false,
    topolegend = nothing,
    topomarkersize = nothing,
    topowidth = nothing,
    topoheigth = nothing,
    topopositions_to_color = nothing,
    mapping = (;),
    kwargs...,
)
    config = PlotConfig(:erp)
    config_kwargs!(config; mapping, kwargs...)
    if butterfly
        config = PlotConfig(:butterfly)
        config_kwargs!(config; mapping, kwargs...)
    end

    plot_data = deepcopy(plot_data) # XXX why?

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

    # Get topocolors for butterfly
    if (butterfly)
        if isnothing(positions) && isnothing(labels)
            topolegend = false
            colors = nothing
        else
            allPositions = getTopoPositions(; positions = positions, labels = labels)
            if (config.visual.colormap !== nothing)
                colors = config.visual.colormap
                un = length(unique(plot_data[:, config.mapping.color]))
                colors = cgrad(config.visual.colormap, un, categorical = true)
            else
                colors = getTopoColor(allPositions, topopositions_to_color)
            end
        end
    end
    # Categorical mapping
    # convert color column into string, so no wrong grouping happens
    if categorical_color && (:color ∈ keys(config.mapping))
        config.mapping =
            merge(config.mapping, (; color = config.mapping.color => nonnumeric))
    end

    # converts group column into string
    if categorical_group && (:group ∈ keys(config.mapping))
        config.mapping =
            merge(config.mapping, (; group = config.mapping.group => nonnumeric))
    end
    #@show colors
    mapp = AlgebraOfGraphics.mapping()

    if (:color ∈ keys(config.mapping))
        mapp = mapp * AlgebraOfGraphics.mapping(; config.mapping.color)
    end

    if (:group ∈ keys(config.mapping))
        mapp = mapp * AlgebraOfGraphics.mapping(; config.mapping.group)
    end

    # remove x / y
    mappingOthers = deleteKeys(config.mapping, [:x, :y])

    xy_mapp =
        AlgebraOfGraphics.mapping(config.mapping.x, config.mapping.y; mappingOthers...)

    basic = visual(Lines; config.visual...) * xy_mapp
    # add band of sdterrors
    if stderror
        m_se = mapping(config.mapping.x, :se_low, :se_high)
        basic = basic + visual(Band, alpha = 0.5) * m_se
    end

    basic = basic * data(plot_data)

    # add the p-values
    if !isempty(pvalue)
        basic = basic + addPvalues(plot_data, pvalue, config)
    end

    plotEquation = basic * mapp

    f_grid = f[1, 1]
    # butterfly plot is drawn slightly different
    if butterfly
        # no extra legend
        # add topolegend
        if (topolegend)
            topoAxis = Axis(
                f_grid,
                width = Relative(topowidth),
                height = Relative(topoheigth),
                halign = 0.05,
                valign = 0.95,
                aspect = 1,
            )
            ix = unique(i -> plot_data[:, config.mapping.group[1]][i], 1:size(plot_data, 1))
            topoplotLegend(
                topoAxis,
                topomarkersize,
                plot_data[ix, config.mapping.color[1]],
                colors,
                allPositions,
            )
        end
        if isnothing(colors)
            drawing = draw!(f_grid, plotEquation; axis = config.axis)
        else
            drawing = draw!(
                f_grid,
                plotEquation;
                axis = config.axis,
                palettes = (color = colors,),
            )
        end
    else
        # draw a normal ERP lineplot        
        drawing = draw!(f_grid, plotEquation; axis = config.axis)
    end
    apply_layout_settings!(config; fig = f, ax = drawing, drawing = drawing)
    return f
end

function eegHeadMatrix(positions, center, radius)
    oldCenter = mean(positions)
    oldRadius, _ = findmax(x -> norm(x .- oldCenter), positions)
    radF = radius / oldRadius
    return Makie.Mat4f(
        radF, 0, 0, 0, 0,
        radF, 0, 0, 0, 0, 1, 0,
        center[1] - oldCenter[1] * radF,
        center[2] - oldCenter[2] * radF, 0, 1,
    )
end

# topopositions_to_color = colors?
function topoplotLegend(axis, topomarkersize, unique_val, colors, allPositions)
    allPositions = unique(allPositions)

    topoMatrix = eegHeadMatrix(allPositions, (0.5, 0.5), 0.5)

    un = unique(unique_val)
    specialColors = ColorScheme(
        vcat(RGB(1, 1, 1.0), colors[map(x -> findfirst(x .== un), unique_val)]),
    )

    xlims!(low = -0.2, high = 1.2)
    ylims!(low = -0.2, high = 1.2)
    topoplot = eeg_topoplot!(
        axis,
        1:length(allPositions), # go from 1:npos
        string.(1:length(allPositions));
        positions = allPositions,
        interpolation = NullInterpolator(), # inteprolator that returns only 0, which is put to white in the specialColorsmap
        colorrange = (0, length(allPositions)), # add the 0 for the white-first color
        colormap = specialColors,
        head = (color = :black, linewidth = 1, model = topoMatrix),
        label_scatter = (markersize = topomarkersize, strokewidth = 0.5),
    )

    hidedecorations!(current_axis())
    hidespines!(current_axis())

    return topoplot
end

function addPvalues(plot_data, pvalue, config)
    p = deepcopy(pvalue)

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
    #@show config.mapping
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

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

- `categorical_color` (bool, `true`): in case of numeric `:color` column, treat `:color` as continuous or categorical variable.
- `categorical_group` (bool, `true`): in case of numeric `:group` column, treat `:group` as categorical variable by default.
- `topolegend` (bool, `false`): add an inlay topoplot with corresponding electrodes.
- `stderror` (bool, `false`): add an error ribbon, with lower and upper limits based on the `:stderror` column.
- `pvalue` (Array, `[]`): show a pvalue.
    - example: `DataFrame(from=[0.1, 0.3], to=[0.5, 0.7], coefname=["(Intercept)", "condition:face"])` -  if coefname is not specified, the lines will be black
- `positions` (nothing): see plot_butterfly.
Internal:
- `butterfly` (bool, `true`): a butterfly plot.

$(_docstring(:erp))

## Return Value:

- f - Figure() or the inputed `f`

"""
plot_erp(plot_data::DataFrame; kwargs...) = plot_erp!(Figure(), plot_data, ; kwargs...)

"""
Plot a butterfly plot
    plot_butterfly(plot_data::DataFrame; positions=nothing) =

## kwargs (...; ...):
- `positions` (bool, `nothing`): Provide 2D layout positions to add a inset based on channel location and color the lines in a logical way
- `topolegend` (bool, `true`): show an inlay topoplot with corresponding electrodes.
- `topomarkersize` (Real, `10`): change the size of the markers, topoplot-inlay electrodes.
- `topowidth` (Real, `0.25`): change the size of the inlay topoplot width.
- `topoheigth` (Real, `0.25`): change the size of the inlay topoplot height.
- `topopositions_to_color` (function, ´x -> posToColorRomaO(x)´).



$(_docstring(:butterfly))
see also [`plot_erp`](@Ref)
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
    kwargs...,
)
    config = PlotConfig(:erp)
    config_kwargs!(config; kwargs...)
    if butterfly
        config = PlotConfig(:butterfly)
        config_kwargs!(config; kwargs...)
    end

    plot_data = deepcopy(plot_data) # XXX why?

    # resolve columns with data
    config.mapping = resolveMappings(plot_data, config.mapping)
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

    # check if stderror values exist and create new collumsn with high and low band
    if "stderror" ∈ names(plot_data) && stderror
        plot_data.stderror = plot_data.stderror .|> a -> isnothing(a) ? 0.0 : a
        plot_data[!, :se_low] = plot_data[:, config.mapping.y] .- plot_data.stderror
        plot_data[!, :se_high] = plot_data[:, config.mapping.y] .+ plot_data.stderror
    end

    # Get topocolors for butterfly
    if (butterfly)
        if isnothing(positions) && isnothing(labels)
            topolegend = false
            #colors = config.visual.colormap# get(colorschemes[config.visual.colormap],range(0,1,length=nrow(plot_data)))
            colors = nothing
            #config.mapping = merge(config.mapping,(;color=config.))
        else
            allPositions = getTopoPositions(; positions = positions, labels = labels)
            colors = getTopoColor(allPositions, topopositions_to_color)
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
    mapp = mapping()

    if (:color ∈ keys(config.mapping))
        mapp = mapp * mapping(; config.mapping.color)
    end

    if (:group ∈ keys(config.mapping))
        mapp = mapp * mapping(; config.mapping.group)
    end

    # remove x / y
    mappingOthers = deleteKeys(config.mapping, [:x, :y])

    xy_mapp = mapping(config.mapping.x, config.mapping.y; mappingOthers...)

    basic = visual(Lines; config.visual...) * xy_mapp
    # add band of sdterrors
    if stderror
        m_se = mapping(config.mapping.x, :se_low, :se_high)
        basic = basic + visual(Band, alpha = 0.5) * m_se
    end

    basic = basic * data(plot_data)

    # add the pvalues
    if !isempty(pvalue)
        basic = basic + addPvalues(plot_data, pvalue, config)
    end

    plotEquation = basic * mapp

    f_grid = f[1, 1]
    # butterfly plot is drawn slightly different
    if butterfly
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
            topoplotLegend(
                topoAxis,
                topomarkersize,
                topopositions_to_color,
                allPositions,
            )
        end
        # no extra legend
        mainAxis = Axis(f_grid; config.axis...)
        hidedecorations!(mainAxis, label = false, ticks = false, ticklabels = false)

        if isnothing(colors)
            drawing = draw!(mainAxis, plotEquation)
        else
            drawing = draw!(mainAxis, plotEquation; palettes = (color = colors,))
        end
    else
        # normal lineplot draw
        #drawing = draw!(Axis(f[1,1]; config.axisData...),plotEquation)

        drawing = draw!(f_grid, plotEquation; axis = config.axis)

    end
    applyLayoutSettings!(config; fig = f, ax = drawing, drawing = drawing)#, drawing = drawing)
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

function topoplotLegend(axis, topomarkersize, topopositions_to_color, allPositions)
    allPositions = unique(allPositions)

    topoMatrix = eegHeadMatrix(allPositions, (0.5, 0.5), 0.5)

    # colorscheme where first entry is 0, and exactly length(positions)+1 entries
    specialColors = ColorScheme(
        vcat(RGB(1, 1, 1.0), [topopositions_to_color(pos) for pos in allPositions]...),
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

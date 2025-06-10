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
    F.e. `mapping = (; col = :group)` will make a column for each group.
- `visual = (; color = Makie.wong_colors, colormap = :roma)`\\
    For categorical color use `visual.color`, for continuous - `visual.colormap`.\\
- `sigifnicance_visual::Symbol = :vspan`\\
    How to display significance intervals. Options:\\
    * `:vspan` – draw vertical shaded spans (default);\\
    * `:lines` – draw horizontal bands below ERP lines;\\
    * `:both` – draw both.\\
- `significance_lines::NamedTuple = (;)`\\
    Configure the appearance of significance lines:\\
    * `linewidth` – thickness of each line (not working);\\
    * `gap` – vertical space between stacked lines. Computed as `stack_step = linewidth + gap`;\\
    * `alpha` – transparency of the lines.\\
    Defaults: $(supportive_defaults(:erp_significance_l_default))
- `significance_vspan::NamedTuple = (;)`\\
    Control appearance of vertical significance spans:\\
    * `alpha` – transparency of the shaded area.\\
    Defaults: $(supportive_defaults(:erp_significance_v_default))
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
    sigifnicance_visual::Symbol = :vspan,
    significance_lines = (;),
    significance_vspan = (;),
    mapping = (;),
    kwargs...,
)
    if !(isnothing(categorical_color) && isnothing(categorical_group))
        @warn "categorical_color and categorical_group have been deprecated.
        To switch to categorical colors, please use `mapping(..., color = :mycolorcolumn => nonnumeric)`.
        `group` is now automatically cast to nonnumeric."
    end
    plot_data = deepcopy(plot_data)
    config = PlotConfig(:erp)
    config_kwargs!(config; mapping, kwargs...)

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
    yticks = round.(
        LinRange(
            minimum(plot_data[!, config.mapping.y]),
            maximum(plot_data[!, config.mapping.y]),
            5,
        ),
        digits = 2,
    )
    xticks =
        round.(LinRange(minimum(plot_data.time), maximum(plot_data.time), 5), digits = 2)
    config_kwargs!(config; axis = (; yticks = yticks, xticks = xticks))

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

    if !haskey(config.mapping, :color)
        if !haskey(config.visual, :color) || config.visual.color isa AbstractVector
            config_kwargs!(config; visual = (; colormap = nothing, color = :black))
            #By default we used `black` color for lines. If you need something else, please specify `config.visual.color`.
        end
        is_categorical = true
    else
        # Determine color mapping
        is_symbolic_color = isa(config.mapping.color, Symbol)
        color_type =
            is_symbolic_color ? AlgebraOfGraphics.nonnumeric : config.mapping.color[2]

        # Check if the color data is categorical
        color_mapper = is_symbolic_color ? config.mapping.color : config.mapping.color[1]
        color_data = plot_data[:, color_mapper]
        is_categorical =
            isa(color_data[1], String) ||
            isa(color_data[1], Bool) ||
            color_type == AlgebraOfGraphics.nonnumeric
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

    # add significance values
    if !isnothing(significance)
        basic = significance_context(
            basic,
            plot_data,
            significance,
            config,
            sigifnicance_visual,
            significance_lines,
            significance_vspan,
        )
    end
    plot_equation = basic * mapp

    f_grid = f[1, 1] = GridLayout()

    # Draw the plot accordingly
    drawing = if is_categorical
        draw!(f_grid, plot_equation; axis = config.axis)  # Categorical case
    else
        draw!(
            f_grid,
            plot_equation,
            scales(Color = (; colormap = config.visual.colormap));
            axis = config.axis,
        )  # Continuous case
    end

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

function significance_context(
    basic,
    plot_data,
    significance,
    config,
    sigifnicance_visual,
    significance_lines,
    significance_vspan,
)
    valid_modes = (:lines, :vspan, :both)
    if !(sigifnicance_visual in valid_modes)
        error("Invalid `sigifnicance_visual`: $sigifnicance_visual. Choose from: $valid_modes")
    end

    # Compute shared context
    y = plot_data[!, config.mapping.y]
    ymin, ymax = minimum(y), maximum(y)
    time_col = config.mapping.x
    time_resolution = diff(plot_data[!, time_col][1:2])[1]

    if sigifnicance_visual in (:lines, :both)
        significance_lines = update_axis(
            supportive_defaults(:erp_significance_l_default); significance_lines...,
        )
        basic += add_lines(
            plot_data, significance, config, significance_lines;
            ymin = ymin, ymax = ymax, time_resolution = time_resolution,
        )
    end

    if sigifnicance_visual in (:vspan, :both)
        significance_vspan = update_axis(
            supportive_defaults(:erp_significance_v_default); significance_vspan...,
        )
        basic += add_vspan(
            plot_data, significance, config, significance_vspan;
            ymin = ymin, ymax = ymax, time_resolution = time_resolution,
        )
    end

    return basic
end

function add_lines(plot_data, significance, config, significance_lines;
    ymin, ymax, time_resolution)

    signif_data = deepcopy(significance)

    # Fallback group logic
    if "group" ∉ names(signif_data)
        if "group" ∈ names(plot_data)
            signif_data[!, :group] .= plot_data[1, :group]
            if length(unique(plot_data.group)) > 1
                @warn "multiple groups found, choosing first one"
            end
        else
            signif_data[!, :group] .= 1
        end
    end

    # Significance index mapping
    if :color ∈ keys(config.mapping)
        c = config.mapping.color isa Pair ? config.mapping.color[1] : config.mapping.color
        un = unique(signif_data[!, c])
        signif_data[!, :signindex] .= [findfirst(un .== x) for x in signif_data.coefname]
    else
        signif_data[!, :signindex] .= 1
    end

    erp_height = ymax - ymin
    linewidth = significance_lines.linewidth * erp_height
    stack_step = linewidth + significance_lines.gap
    base_y = ymin - 0.05 * erp_height

    signif_data[!, :segments] = [
        Makie.Rect(
            Makie.Vec(from, base_y + stack_step * (n - 1)),
            Makie.Vec(to - from + time_resolution, linewidth),
        ) for
        (from, to, n) in zip(signif_data.from, signif_data.to, signif_data.signindex)
    ]

    return data(signif_data) * mapping(:segments) *
           visual(Poly, alpha = significance_lines.alpha)
end

function add_vspan(plot_data, significance, config, significance_vspan;
    ymin, ymax, time_resolution)

    vspan_data = deepcopy(significance)

    vspan_data[!, :vspan] = [
        Makie.Rect(
            Makie.Vec(from, ymin),
            Makie.Vec(to - from + time_resolution, ymax - ymin),
        ) for (from, to) in zip(significance.from, significance.to)
    ]

    return data(vspan_data) * mapping(:vspan) *
           visual(Poly; alpha = significance_vspan.alpha)
end

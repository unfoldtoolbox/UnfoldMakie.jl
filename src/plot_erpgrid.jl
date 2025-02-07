"""
    plot_erpgrid(data::Union{Matrix{<:Real}, DataFrame}, positions::Vector; kwargs...)
    plot_erpgrid!(f::Union{GridPosition, GridLayout, Figure}, data::Union{Matrix{<:Real}, DataFrame}, positions::Vector, ch_names::Vector{String}; kwargs...)

Plot an ERP image.
## Arguments
- `f::Union{GridPosition, GridLayout, Figure}`\\
    `Figure`, `GridLayout`, or `GridPosition` to draw the plot.
- `data::Union{Matrix{<:Real}, DataFrame}`\\
    Data for the plot visualization.\\
    Data should has a format of 1 row - 1 channel. 
- `positions::Vector{Point{2,Float}}` \\
    Electrode positions.
- `ch_names::Vector{String}`\\
    Vector with channel names.
- `hlines_grid_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the hlines on all subaxes.\\
    To see all options just type `?hlines` in REPL.\\
    Defaults: $(supportive_defaults(:hlines_grid_default))
- `vlines_grid_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the vlines on all subaxes.\\
    To see all options just type `?vlines` in REPL.\\
    Defaults: $(supportive_defaults(:vlines_grid_default))
- `lines_grid_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the lines on all subaxes.\\
    To see all options just type `?lines` in REPL.\\
    Defaults: $(supportive_defaults(:lines_grid_default))
- `labels_grid_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the labels on all subaxes.\\
    To see all options just type `?text` in REPL.\\
    Defaults: $(supportive_defaults(:labels_grid_default))
        
## Keyword arguments (kwargs)
- `drawlabels::Bool = false`\\
    Draw channels labels over each waveform. 
- `times::Vector = 1:size(data, 2)`\\
    Vector of `size()`.

$(_docstring(:erpgrid))

**Return Value:** `Figure` displaying ERP grid.
"""
plot_erpgrid(
    data::Union{Matrix{<:Real},DataFrame},
    positions::Vector,
    ch_names::Vector{String};
    kwargs...,
) = plot_erpgrid!(Figure(), data, positions, ch_names; kwargs...)

plot_erpgrid!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Union{Matrix{<:Real},DataFrame},
    positions;
    kwargs...,
) = plot_erpgrid!(f, data, positions, string.(1:length(positions)); kwargs...)

plot_erpgrid(data::Union{Matrix{<:Real},DataFrame}, positions; kwargs...) =
    plot_erpgrid!(Figure(), data, positions, string.(1:length(positions)); kwargs...)

function plot_erpgrid!(
    f::Union{GridPosition,GridLayout,Figure},
    data::Union{Matrix{<:Real},DataFrame},
    positions::Vector,
    ch_names::Vector{String};
    drawlabels = false,
    times = -1:size(data, 2)-2, #arbitrary
    labels_grid_axis = (;),
    hlines_grid_axis = (;),
    vlines_grid_axis = (;),
    lines_grid_axis = (;),
    kwargs...,
)
    data = validate_inputs(data, positions, ch_names)
    positions = normalize_positions(positions)
    config = PlotConfig(:erpgrid)
    config_kwargs!(config; kwargs...)

    axlist = []
    rel_zeropoint = argmin(abs.(times)) ./ length(times)
    labels_grid_axis =
        update_axis(supportive_defaults(:labels_grid_default); labels_grid_axis...)
    for (ix, p) in enumerate(eachcol(positions))
        ax = Axis(
            f[1, 1],
            width = Relative(0.1),
            height = Relative(0.1),
            halign = p[1],
            valign = p[2],
        )
        if drawlabels
            text!(ax, rel_zeropoint + 0.1, 1; text = ch_names[ix], labels_grid_axis...)
        end
        # todo: add label if not nothing
        push!(axlist, ax)
    end

    hlines_grid_axis =
        update_axis(supportive_defaults(:hlines_grid_default); hlines_grid_axis...)
    vlines_grid_axis =
        update_axis(supportive_defaults(:vlines_grid_default); vlines_grid_axis...)
    lines_grid_axis =
        update_axis(supportive_defaults(:lines_grid_default); lines_grid_axis...)

    hlines!.(axlist, Ref([0.0]); hlines_grid_axis...)
    vlines!.(axlist, Ref([0.0]); vlines_grid_axis...)

    times = isnothing(times) ? (1:size(data, 2)) : times

    # todo: add customizable kwargs
    lines!.(axlist, Ref(times), eachrow(data); lines_grid_axis...)

    linkaxes!(axlist...)
    hidedecorations!.(axlist)
    hidespines!.(axlist)

    ax2 = Axis(f[1, 1], width = Relative(1.05), height = Relative(1.05))
    hidespines!(ax2)
    hidedecorations!(ax2, label = false)
    xlims!(ax2, config.axis.xlim)
    ylims!(ax2, config.axis.ylim)
    xstart = [Point2f(0), Point2f(0)]
    xdir = [Vec2f(0, 0.1), Vec2f(0.1, 0)]
    arrows!(xstart, xdir, arrowsize = 10)
    text!(
        0.02,
        0,
        text = config.axis.xlabel,
        fontsize = config.axis.fontsize,
        align = (:left, :top),
    )
    text!(
        -0.008,
        0.01,
        text = config.axis.ylabel,
        fontsize = config.axis.fontsize,
        align = (:left, :baseline),
        rotation = π / 2,
    )
    f
end


# Helper function for validation
function validate_inputs(data, positions, ch_names)
    if isa(data, DataFrame)
        data = Matrix(data)
    end
    if length(positions) != length(ch_names)
        error(
            "Length of positions and channel names are not equal: $(length(positions)) and $(length(ch_names))",
        )
    end
    if size(data, 1) != length(positions)
        error(
            "Number of data rows and positions length are not equal: $(size(data, 1)) and $(length(positions))",
        )
    end
    return data
end

# Normalize positions
function normalize_positions(positions)
    pos_matrix = hcat([[p[1], p[2]] for p in positions]...)
    minmaxrange = maximum(pos_matrix, dims = 2) - minimum(pos_matrix, dims = 2)
    normalized = (pos_matrix .- mean(pos_matrix, dims = 2)) ./ minmaxrange .+ 0.5
    return normalized
end

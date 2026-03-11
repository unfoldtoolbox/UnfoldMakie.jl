"""
     eeg_topoplot_series(data::DataFrame,
        fig,
        data_inp::Union{<:Observable,<:AbstractMatrix};
        layout = nothing,
        topoplot_xlabels = nothing,
        labels = nothing,
        rasterize_heatmaps = true,
        interactive_scatter = nothing,
        highlight_scatter = false,
        topo_axis = (;),
        topo_attributes = (;),
        positions,
    )
    eeg_topoplot_series!(fig, data::DataFrame; kwargs..)

Plot a series of topoplots. 
The function takes the `combinefun = mean` over the `:time` column of `data`.
- `fig` \\
    Figure object. \\
- `data::Union{<:Observable,<:AbstractMatrix}`\\
    Matrix with size = (n_channel, n_topoplots).
- `layout::Vector{Tuple{Int64, Int64}}`\\
    Vector of tuples with coordinates for each topoplot.
- `topoplot_xlabels::Vector{String}`\\
    Vector of xlables for each topoplot. 
- `topo_axis::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot axis.\\
    To see all options just type `?Axis` in REPL.\\
    Defaults: $(supportive_defaults(:topo_default_series))
- `topo_attributes::NamedTuple = (;)`\\
    Here you can flexibly change configurations of the topoplot interoplation.\\
    To see all options just type `?Topoplot.topoplot` in REPL.\\
    Defaults: $(replace(string(supportive_defaults(:topo_default_attributes; docstring = true)), "_" => "\\_")).
- `positions::Vector{Point{2, Float32}}`\\
    Channel positions. The list of x and y positions for all unique electrodes. 

**Return Value:** `Tuple{Figure, Vector{Any}}`.
"""
function eeg_topoplot_series(
    data::Union{<:Observable,<:DataFrame,<:AbstractMatrix};
    figure = NamedTuple(),
    kwargs...,
)
    return eeg_topoplot_series!(Figure(; figure...), data; kwargs...)
end

function eeg_topoplot_series!(
    fig,
    data_inp::Union{<:Observable,<:AbstractMatrix};
    layout = nothing,
    topoplot_xlabels = nothing, # can be a vector too
    row_labels = nothing,
    rasterize_heatmaps = true,
    interactive_scatter = nothing,
    highlight_scatter = false,
    topo_axis = (;),
    topo_attributes = (;),
    positions,
    labels = nothing,
)
    # for performance, new variable name is necessary, as type might change
    data = _as_observable(data_inp)

    topo_axis = update_axis(supportive_defaults(:topo_default_series); topo_axis...)

    # do the col/row plot
    axlist = []
    if interactive_scatter != nothing
        @assert isa(interactive_scatter, Observable)
    end

    r_vec, c_vec = init_grid(layout, data, fig)
    r_max = maximum(r_vec)
    if row_labels !== nothing && length(to_value(row_labels)) != r_max
        throw(
            ArgumentError(
                "Length of row_labels must be equal to the number of rows in layout. Currently: $(length(to_value(row_labels))) != $r_max",
            ),
        )
    end

    for t_idx = 1:size(to_value(data), 2)
        single_y = @lift $data[:, t_idx]
        r = r_vec[t_idx]
        c = c_vec[t_idx]
        ax = Axis(fig[r, c]; topo_axis...)

        if row_labels !== nothing
            if c == 1
                ax.ylabel = string(to_value(row_labels)[r])
            end
            if r == r_max
                ax.xlabel =
                    isnothing(topoplot_xlabels) ? "" :
                    string(to_value(topoplot_xlabels)[t_idx])
            end
        else
            ax.xlabel =
                isnothing(topoplot_xlabels) ? "" : string(to_value(topoplot_xlabels)[t_idx])
        end

        # select data
        topo_attributes = scatter_management(
            single_y,
            topo_attributes,
            highlight_scatter,
            interactive_scatter,
        )
        single_topoplot = eeg_topoplot!(ax, single_y; positions, labels, topo_attributes...)
        if rasterize_heatmaps
            single_topoplot.plots[1].plots[1].rasterize = true
        end
        interactive_toposeries(interactive_scatter, ax, single_topoplot, positions, r, c)
        push!(axlist, ax)

    end
    if typeof(fig) != GridLayout && typeof(fig) != GridLayoutBase.GridSubposition
        colgap!(fig.layout, 0)
    end
    return fig, axlist
end

function init_grid(layout, data, fig)
    # Initialize vectors for r and c
    r_vec = Vector{Int}()
    c_vec = Vector{Int}()

    # Populate r_vec and c_vec based on layout or default values
    if isnothing(layout)
        for t_idx = 1:size(to_value(data), 2)
            push!(r_vec, 1)
            push!(c_vec, size(fig.layout, 2) + t_idx)
        end
    else
        for t_idx = 1:size(to_value(data), 2)
            push!(r_vec, layout[t_idx][1])
            push!(c_vec, layout[t_idx][2])
        end
    end
    return r_vec, c_vec
end

function scatter_management(
    single_y,
    topo_attributes,
    highlight_scatter,
    interactive_scatter,
)
    if highlight_scatter != false || interactive_scatter != nothing
        #strokecolor = Observable(repeat([:black], length(to_value(single_y))))
        strokecolor = Observable(repeat([:black], length(to_value(single_y)))) # black
        highlight_feature = (; strokecolor = strokecolor)

        if :label_scatter ∈ keys(topo_attributes) &&
           isa(topo_attributes[:label_scatter], NamedTuple)
            label_scatter = merge(topo_attributes[:label_scatter], highlight_feature)
        else
            label_scatter = highlight_feature
        end
        topo_attributes = update_axis(topo_attributes; label_scatter = label_scatter)
    end
    return topo_attributes
end

#= function interactive_toposeries(interactive_scatter, single_topoplot, r, c)
    if interactive_scatter != nothing
        @assert isa(interactive_scatter, Observable)
    end
    if interactive_scatter != false
        on(events(single_topoplot).mousebutton) do event
            if event.button == Mouse.left && event.action == Mouse.press
                plt, p = pick(single_topoplot)
                if isa(plt, Makie.Scatter) && plt == single_topoplot.plots[1].plots[3]
                    plt.strokecolor[] .= Makie.to_color(:black)
                    plt.strokecolor[][p] = Makie.to_color(:white)
                    notify(plt.strokecolor) # not sure why this is necessary, but oh well..
                    interactive_scatter[] = (r, c, p)
                end
            end
        end
    end
end =#

function interactive_toposeries(interactive_scatter, ax, single_topoplot, positions, r, c)
    (interactive_scatter === nothing || interactive_scatter === false) && return
    @assert interactive_scatter isa Observable

    scatter_plot = single_topoplot.plots[1].plots[3]  # fragile, but current working version
    black = Makie.to_color(:black)
    white = Makie.to_color(:white)

    on(events(ax.scene).mousebutton) do event
        if event.button == Mouse.left && event.action == Mouse.press
            Makie.is_mouseinside(ax.scene) || return
            mouse_pos = mouseposition(ax.scene)
            electrode_idx = closest_electrode_index(mouse_pos, positions)

            stroke_colors = scatter_plot.strokecolor[]
            stroke_colors .= black
            stroke_colors[electrode_idx] = white
            notify(scatter_plot.strokecolor)

            interactive_scatter[] = (r, c, electrode_idx)
        end
    end
end

function closest_electrode_index(mouse_pos, positions)
    best_idx = 1
    best_dist_sq = Inf

    for i in eachindex(positions)
        dx = positions[i][1] - mouse_pos[1]
        dy = positions[i][2] - mouse_pos[2]
        dist_sq = dx * dx + dy * dy

        if dist_sq < best_dist_sq
            best_dist_sq = dist_sq
            best_idx = i
        end
    end

    return best_idx
end

"""
    eeg_array_to_dataframe(data::AbstractMatrix, label_aliases::AbstractVector)
    eeg_array_to_dataframe(data::AbstractVector, label_aliases::AbstractVector)
    eeg_array_to_dataframe(data::Union{AbstractMatrix, AbstractVector{<:Number}})
    
Helper function converting an array (Matrix or Vector) to a tidy `DataFrame` with columns `:estimate`, `:time` and `:label` (with aliases `:color`, `:group`, `:channel`).

Format of Arrays:\\
- times x condition for plot\\_erp.\\
- channels x time for plot\\_butterfly, plot\\_topoplotseries.\\
- channels for plot\\_topoplot.\\

**Return Value:** `DataFrame`.
"""
eeg_array_to_dataframe(data::Union{AbstractMatrix,AbstractVector{<:Number}}) =
    eeg_array_to_dataframe(data, string.(1:size(data, 1)))

eeg_array_to_dataframe(data::AbstractVector, label_aliases::AbstractVector) =
    eeg_array_to_dataframe(reshape(data, 1, :), label_aliases)

function eeg_array_to_dataframe(data::AbstractMatrix, label_aliases::AbstractVector)
    array_to_df(data, label_aliases) = DataFrame(data', label_aliases)
    array_to_df(data::LinearAlgebra.Adjoint{<:Number,<:AbstractVector}, label_aliases) =
        DataFrame(collect(data)', label_aliases)

    df = array_to_df(data, label_aliases)
    df[!, :time] .= 1:nrow(df)

    df = stack(df, Not([:time]); variable_name = :label_aliases, value_name = "estimate")
    df.color = df.label_aliases
    df.group = df.label_aliases
    df.channel = df.label_aliases
    return df
end

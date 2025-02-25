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

    for t_idx = 1:size(to_value(data), 2)

        single_y = @lift $data[:, t_idx]
        if isnothing(layout)
            r = 1
            c = size(fig.layout, 2) + 1

        else
            r = layout[t_idx][1]
            c = layout[t_idx][2]
        end
        ax = Axis(
            fig[r, c];
            topo_axis...,
            xlabel = isnothing(topoplot_xlabels) ? "" : to_value(topoplot_xlabels)[t_idx],
        )
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
        interactive_toposeries(interactive_scatter, single_topoplot, r, c) #TODO
        push!(axlist, ax)

    end
    if typeof(fig) != GridLayout && typeof(fig) != GridLayoutBase.GridSubposition
        colgap!(fig.layout, 0)
    end
    return fig, axlist
end

function scatter_management( # should be cheked and simplified
    single_y,
    topo_attributes,
    highlight_scatter,
    interactive_scatter,
)
    if highlight_scatter != false || interactive_scatter != nothing
        strokecolor = Observable(repeat([:black], length(to_value(single_y))))
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

function interactive_toposeries(interactive_scatter, single_topoplot, r, c)
    if interactive_scatter != nothing
        @assert isa(interactive_scatter, Observable)
    end
    if interactive_scatter != false
        on(events(single_topoplot).mousebutton) do event
            if event.button == Mouse.left && event.action == Mouse.press
                plt, p = pick(single_topoplot)
                if isa(plt, Makie.Scatter) && plt == single_topoplot.plots[1].plots[3]
                    plt.strokecolor[] .= :black
                    plt.strokecolor[][p] = :white
                    notify(plt.strokecolor) # not sure why this is necessary, but oh well..
                    interactive_scatter[] = (r, c, p)
                end
            end
        end
    end
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

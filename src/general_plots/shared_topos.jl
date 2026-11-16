function shared_percentile_ranges(data, predictor)
    x = combine(
        groupby(DataFrame(:e => data, :p => predictor), :p),
        :e => (x -> maximum(abs.(quantile!(x, [0.01, 0.99])))) => :local_max_val,
    )
    global_max_val = maximum(x.local_max_val)
    return (-global_max_val, global_max_val)
end

function topo_colorrange_mode(visual)
    mode = get(visual, :colorrange_mode, :diverging_balanced)
    if mode in (:diverging_balanced, :divering_balanced)
        return :diverging_balanced
    elseif mode == :sequential
        return :sequential
    else
        error("visual.colorrange_mode must be :diverging_balanced or :sequential")
    end
end

topo_sequential_colormap() = :viridis
topo_default_diverging_colormap() = Reverse(:RdBu)

function topo_resolved_visual(visual)
    mode = topo_colorrange_mode(visual)
    resolved_visual = (; (k => v for (k, v) in pairs(visual) if k != :colorrange_mode)...)
    if mode == :sequential
        current_colormap = get(resolved_visual, :colormap, nothing)
        if isnothing(current_colormap) || current_colormap == topo_default_diverging_colormap()
            return update_axis(resolved_visual; colormap = topo_sequential_colormap())
        else
            return resolved_visual
        end
    else
        return resolved_visual
    end
end

function _topo_range_from_values(values; colorrange_mode = :diverging_balanced)
    vals = collect(skipmissing(vec(values)))
    if colorrange_mode == :sequential
        q05, q95 = quantile(vals, [0.05, 0.95])
        return Float32.((q05, q95))
    elseif any(<(0), vals)
        p01, p99 = quantile(vals, [0.01, 0.99])
        m = max(abs(p01), abs(p99))
        return Float32.((-m, m))
    else
        return Float32.((minimum(vals), maximum(vals)))
    end
end

function topo_shared_range(data, visual)
    colorrange_mode = topo_colorrange_mode(visual)
    if data isa Observable
        if haskey(visual, :colorrange)
            return Observable(Float32.(visual.colorrange))
        elseif haskey(visual, :limits)
            return Observable(Float32.(visual.limits))
        else
            return @lift _topo_range_from_values($data; colorrange_mode = colorrange_mode)
        end
    else
        if haskey(visual, :colorrange)
            return Float32.(visual.colorrange)
        elseif haskey(visual, :limits)
            return Float32.(visual.limits)
        else
            return _topo_range_from_values(data; colorrange_mode = colorrange_mode)
        end
    end
end

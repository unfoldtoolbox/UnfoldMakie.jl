function shared_percentile_ranges(data, predictor)
    x = combine(
        groupby(DataFrame(:e => data, :p => predictor), :p),
        :e => (x -> maximum(abs.(quantile!(x, [0.01, 0.99])))) => :local_max_val,
    )
    global_max_val = maximum(x.local_max_val)
    return (-global_max_val, global_max_val)
end

function _topo_range_from_values(values)
    if any(<(0), values)
        p01 = _percentile(0.01, values)
        p99 = _percentile(0.99, values)
        m = max(abs(p01), abs(p99))
        return Float32.((-m, m))
    else
        return Float32.((minimum(values), maximum(values)))
    end
end

function topo_shared_range(data, visual)
    if data isa Observable
        if haskey(visual, :colorrange)
            return Observable(Float32.(visual.colorrange))
        elseif haskey(visual, :limits)
            return Observable(Float32.(visual.limits))
        else
            return @lift _topo_range_from_values($data)
        end
    else
        if haskey(visual, :colorrange)
            return Float32.(visual.colorrange)
        elseif haskey(visual, :limits)
            return Float32.(visual.limits)
        else
            return _topo_range_from_values(data)
        end
    end
end

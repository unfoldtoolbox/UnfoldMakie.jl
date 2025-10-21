using DataFrames
using TopoPlots
using LinearAlgebra

"""
    _normalize_nticks(nticks)

Normalize `nticks` to `(x::Int, y::Int)`. Accepts:
- `Int` → same for both axes
- `(Int, Int)` → `(x, y)`
- `(x=Int, y=Int)` → as-is

Errors on any other shape.

**Return Value:** `NamedTuple{(:x, :y), Tuple{Int, Int}}`.
"""
function _normalize_nticks(nticks)
    if nticks isa Integer
        return (x = nticks, y = nticks)
    elseif nticks isa Tuple{<:Integer,<:Integer}
        return (x = nticks[1], y = nticks[2])
    elseif nticks isa NamedTuple
        haskey(nticks, :x) && haskey(nticks, :y) ||
            error("nticks must have keys :x and :y")
        nticks.x isa Integer || error("nticks.x must be Int")
        nticks.y isa Integer || error("nticks.y must be Int")
        return (x = nticks.x, y = nticks.y)
    else
        error("nticks must be Int, (Int,Int), or (x=Int,y=Int)")
    end
end

@views function apply_nticks(config, plot_data, nticks)
    m, a = config.mapping, config.axis
    needx = haskey(m, :x) && !haskey(a, :xticks)
    needy = haskey(m, :y) && !haskey(a, :yticks)
    !(needx || needy) && return config
    nt = _normalize_nticks(nticks)
    if needx
        xticks_auto =
            default_tick_positions(view(plot_data, :, config.mapping.x); nticks = nt.x)
        config.axis = merge(config.axis, (; xticks = xticks_auto))
    end
    if needy
        yticks_auto =
            default_tick_positions(view(plot_data, :, config.mapping.y); nticks = nt.y)
        config.axis = merge(config.axis, (; yticks = yticks_auto))
    end
    return config
end

# remove mapping values with `nothing`
deleteKeys(nt::NamedTuple{names}, keys) where {names} =
    NamedTuple{filter(x -> x ∉ keys, names)}(nt)

function erp_butterfly_mapping(plot_data, config, nticks)

    # resolve columns with data
    config.mapping = resolve_mappings(plot_data, config.mapping)
    apply_nticks(config, plot_data, nticks)

    config.mapping = deleteKeys(
        config.mapping,
        keys(config.mapping)[findall(isnothing.(values(config.mapping)))],
    )
    # turn "nothing" from group columns into :fixef
    if "group" ∈ names(plot_data)
        plot_data.group = plot_data.group .|> a -> isnothing(a) ? :fixef : a
    end
    return plot_data, config
end

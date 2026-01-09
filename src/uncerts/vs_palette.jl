function dummy_and_topo_axis(; xlabel = "Voltage [µV]",
    ylabel = "Standard deviation")
    ax_dummy = Axis(f[1:4, 3:4],
        xlabel = xlabel,
        ylabel = ylabel,
        yaxisposition = :right,
        xaxisposition = :top,
        xlabelsize = 24, ylabelsize = 24,
        width = 230, height = 210,
    )
    hidedecorations!(ax_dummy, label = false)
    hidespines!(ax_dummy)
    
    topo_axis = Axis(f[1:4, 1:2], aspect = DataAspect(), 
    xlabel = "Time window [340 ms]", xlabelsize = 24)
    hidedecorations!(topo_axis, label = false)
    hidespines!(topo_axis)
    return ax_dummy, topo_axis
end

function flatten_vsp_colors(index_groups, color_groups, n::Int)
    flat_colors = Vector{RGBA{Float32}}(undef, n)

    for (indices, colors) in zip(index_groups, color_groups)
        for (idx, color) in zip(indices, colors)
            flat_colors[idx] = color
        end
    end

    return flat_colors
end


## DESATURATION
# Helper functions
function desaturate(col::T, amount)::T where T
    col_lch = LCHuv(col)
    return LCHuv(col_lch.l, col_lch.c * (1-amount), col_lch.h)
end

function lighten(col::T, amount)::T where T
    col_hsl = HSL(col)
    return HSL(col_hsl.h, col_hsl.s, 1 - (1 - col_hsl.l) * (1-amount))
end

# Generate a color matrix
function vsup_colormatrix(;
    cmap, n_uncertainty, 
    max_desat, # 0-1, 1 = most desaturated is grey, 0 = no desaturation
    pow_desat, # higher values to desature more slowly
    max_light, # 0-1 1 = most light is white, 0 = no light
    pow_light  # higher values to lighten more slowly
)

    n_levels = [2^(i-1) for i in 1:n_uncertainty]
    max_levels = n_levels[end]

    rel_col = @. (ceil(Int, (1:max_levels)'/(max_levels/n_levels)) - 0.5) / n_levels
    col_shift = @. 1 - ((1:n_uncertainty) - 1)/(n_uncertainty - 1)

    col = getindex.(Ref(cmap), rel_col)
    col_desat = desaturate.(
        col, 
        max_desat.*col_shift.^pow_desat
    )
    return lighten.(
        col_desat,
        max_light.*col_shift.^pow_light
    )
end

function vsp_polar_legend!(ax::PolarAxis; vsp_rows, 
    value_labels::AbstractVector{<:AbstractString},
    uncert_labels::AbstractVector{<:AbstractString},
    thetalims=(-π/5, π/5), theta0=π/2)

    ax.thetalimits = thetalims
    ax.theta_0 = theta0
    n_sectors = length(vsp_rows[1])
    radial_steps = 1.0:-1/length(vsp_rows):0.0
    θs = range(thetalims[2], thetalims[1]; length=n_sectors+1) .+ theta0

    for (j, r₁) in enumerate(radial_steps[1:end-1])
        r₂ = radial_steps[j+1]
        for i in 1:n_sectors
            θ₁ = θs[i]; θ₂ = θs[i+1]
            p1 = Point2f(r₁ * cos(θ₁), r₁ * sin(θ₁))
            p2 = Point2f(r₂ * cos(θ₁), r₂ * sin(θ₁))
            p3 = Point2f(r₂ * cos(θ₂), r₂ * sin(θ₂))
            p4 = Point2f(r₁ * cos(θ₂), r₁ * sin(θ₂))
            poly!(ax, [p1, p2, p3, p4], color = vsp_rows[j][i], strokewidth = 0)
        end
    end

    ax.thetaticks = (collect(range(thetalims[1], thetalims[2]; length=length(value_labels))), value_labels)
    ax.rticks = (range(0,1; length=length(uncert_labels)) |> collect, uncert_labels)
    Makie.tightlimits!(ax)
    return ax
end


"""
    vsp_rows_to_colorbox(vsp_rows; T=Float32, flip_rows=false) -> Matrix{RGBA{T}}

Convert a Vector{Vector{<:Colorant}} like your `vsp_rows` into a dense color
matrix suitable for `sample_bivariate` (rows = uncertainty, cols = value).

- If `flip_rows=true`, reverse the row order (useful if your `vsp_rows` are
  ordered outer→inner but your V∈[0,1] increases top→bottom).
"""
function vsp_rows_to_colorbox(vsp_rows; T=Float32, flip_rows::Bool=false)
    @assert !isempty(vsp_rows) "vsp_rows is empty"
    n_rows = length(vsp_rows)
    n_cols = length(vsp_rows[1])
    @assert all(length(r) == n_cols for r in vsp_rows) "All rows must have same length"

    rows = flip_rows ? reverse(vsp_rows) : vsp_rows
    box = Array{RGBA{T}}(undef, n_rows, n_cols)

    @inbounds for i in 1:n_rows, j in 1:n_cols
        c  = rows[i][j]
        rgb = convert(RGB{T}, c)
        a   = T(alpha(c))
        box[i, j] = RGBA{T}(rgb.r, rgb.g, rgb.b, a)
    end
    return box
end

#vsp_rows_to_colorbox(vsp_rows)
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

  n_levels = [2^(i-1) for i in 1:8]
    max_levels = n_levels[end]

function vsp_polar_legend!(ax::PolarAxis; vsp_rows,
    value_labels::AbstractVector{<:AbstractString},
    uncert_labels::AbstractVector{<:AbstractString},
    thetalims=(-π/5, π/5), theta0=π/2)

    ax.thetalimits = thetalims
    ax.theta_0 = theta0

    n_sectors = length(vsp_rows[1])
    n_rings   = length(vsp_rows)

    rs = range(1, 0; length=n_rings+1)
    θs = range(thetalims[1], thetalims[2]; length=n_sectors+1)

    for j in 1:n_rings
        r₁, r₂ = rs[j], rs[j+1]
        for i in 1:n_sectors
            θ₁, θ₂ = θs[i], θs[i+1]

            poly!(ax,
                Point2f[
                    Point2f(θ₁, r₁),
                    Point2f(θ₁, r₂),
                    Point2f(θ₂, r₂),
                    Point2f(θ₂, r₁),
                ],
                color = vsp_rows[j][end - i + 1],
                strokewidth = 0,
            )
        end
    end

    ax.thetaticks = (
        range(thetalims[1], thetalims[2]; length=length(value_labels)),
        value_labels,
    )
    ax.rticks = (range(0,1; length=length(uncert_labels)), uncert_labels)

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

# Clip vec_estimate to symmetric 1st/99th-percentile range when data has negatives.
function _percentile(p::Real, v::AbstractVector)
    n = length(v)
    n == 0 && throw(ArgumentError("percentile of empty collection"))
    s = sort(v)
    idx = clamp(ceil(Int, p * n), 1, n)
    return s[idx]
end



#= 
function vsp_polar_legend_continuous!(
    ax::PolarAxis;
    cmap,
    value_labels::AbstractVector{<:AbstractString},
    uncert_labels::AbstractVector{<:AbstractString},
    thetalims = (-π/5, π/5),
    theta0 = π/2,

    # Geometry resolution
    angular_resolution::Int = 180,
    radial_resolution::Int  = 90,

    # Orientation
    flip_value_direction::Bool = true,
    low_uncertainty_outside::Bool = true,

    # Uncertainty fading
    chroma_fade_strength::Real = 1.0,
    chroma_fade_gamma::Real    = 1.0,

    lightness_fade_strength::Real = 1.0,
    lightness_fade_gamma::Real    = 1.0,

    # NEW
    fade_to_gray::Bool = false   # if true → desaturate only (no lightening)
)
    cmap = cmap isa Symbol ? cgrad(cmap) : cmap

    ax.thetalimits = thetalims
    ax.theta_0 = theta0

    θ0, θ1 = thetalims

    θedges = range(θ0, θ1; length = angular_resolution + 1)
    rmin = 0.03f0  # try 0.02–0.06 depending on size
    redges = range(1.0f0, rmin; length = radial_resolution + 1)
    #redges = range(1.0, 0.0; length = radial_resolution + 1)

    polys  = Vector{Vector{Point2f}}(undef, angular_resolution * radial_resolution)
    colors = Vector{RGB{Float32}}(undef, angular_resolution * radial_resolution)

    k = 0
    @inbounds for ir in 1:radial_resolution
        r1, r2 = redges[ir], redges[ir + 1]
        rmid = (r1 + r2) / 2



        v = low_uncertainty_outside ? (1 - rmid) : rmid

        chroma_amount = clamp(chroma_fade_strength * (v^chroma_fade_gamma), 0, 1)
        light_amount  = clamp(lightness_fade_strength * (v^lightness_fade_gamma), 0, 1)

        for iθ in 1:angular_resolution
            θ1e, θ2e = θedges[iθ], θedges[iθ + 1]
            θmid = (θ1e + θ2e) / 2

            u = (θmid - θ0) / (θ1 - θ0)
            u = flip_value_direction ? (1 - u) : u

            base = getindex(cmap, u)

            # --- desaturation ---
            lch = LCHuv(base)
            c1 = LCHuv(lch.l, lch.c * (1 - chroma_amount), lch.h)

            # --- lightening (optional) ---
            if fade_to_gray
                c_final = RGB{Float32}(c1)
            else
                hsl = HSL(RGB(c1))
                c2 = HSL(hsl.h, hsl.s, 1 - (1 - hsl.l) * (1 - light_amount))
                c_final = RGB{Float32}(c2)
            end

            k += 1
            polys[k] = Point2f[
                Point2f(θ1e, r1),
                Point2f(θ1e, r2),
                Point2f(θ2e, r2),
                Point2f(θ2e, r1),
            ]
            colors[k] = c_final
        end
    end

    poly!(ax, polys; color = colors, strokewidth = 0)

    ax.thetaticks = (
        range(θ0, θ1; length = length(value_labels)),
        value_labels,
    )

    ax.rticks = (
        range(1, 0; length = length(uncert_labels)),
        uncert_labels,
    )

    Makie.tightlimits!(ax)
    return ax
end

 =#
function sample_vsup_bilinear(vsup_cmap, u::Real, v::Real)
    nV, nU = size(vsup_cmap)

    uf = clamp(Float32(u), 0f0, 1f0)
    vf = clamp(Float32(v), 0f0, 1f0)

    x = uf * (nU - 1)
    y = vf * (nV - 1)

    x0 = floor(Int, x) + 1
    y0 = floor(Int, y) + 1

    x1 = min(x0 + 1, nU)
    y1 = min(y0 + 1, nV)

    tx = x - floor(x)
    ty = y - floor(y)

    c00 = RGB{Float32}(vsup_cmap[y0, x0])
    c10 = RGB{Float32}(vsup_cmap[y0, x1])
    c01 = RGB{Float32}(vsup_cmap[y1, x0])
    c11 = RGB{Float32}(vsup_cmap[y1, x1])

    # bilinear interpolation in RGB
    r = (1-ty)*((1-tx)*c00.r + tx*c10.r) + ty*((1-tx)*c01.r + tx*c11.r)
    g = (1-ty)*((1-tx)*c00.g + tx*c10.g) + ty*((1-tx)*c01.g + tx*c11.g)
    b = (1-ty)*((1-tx)*c00.b + tx*c10.b) + ty*((1-tx)*c01.b + tx*c11.b)

    return RGB{Float32}(r, g, b)
end
function vsp_polar_legend_continuous!(
    ax::PolarAxis;
    vsup_cmap,
    value_labels::AbstractVector{<:AbstractString},
    uncert_labels::AbstractVector{<:AbstractString},
    thetalims = (-π/5, π/5),
    theta0 = π/2,
    angular_resolution::Int = 180,
    radial_resolution::Int  = 100,
    flip_value_direction::Bool = true,
    low_uncertainty_outside::Bool = true,
)

    ax.thetalimits = thetalims
    ax.theta_0 = theta0

    θ0, θ1 = thetalims

    # avoid r = 0 degeneracy (prevents center cross artifact)
    rmin = 0.02f0

    θedges = range(θ0, θ1; length = angular_resolution + 1)
    redges = range(1.0f0, rmin; length = radial_resolution + 1)

    polys  = Vector{Vector{Point2f}}(undef, angular_resolution * radial_resolution)
    colors = Vector{RGB{Float32}}(undef, angular_resolution * radial_resolution)

    k = 0
    @inbounds for ir in 1:radial_resolution
        r1, r2 = redges[ir], redges[ir + 1]
        rmid = (r1 + r2) / 2

        v = low_uncertainty_outside ? (1 - rmid) : rmid

        for iθ in 1:angular_resolution
            θ1e, θ2e = θedges[iθ], θedges[iθ + 1]
            θmid = (θ1e + θ2e) / 2

            u = (θmid - θ0) / (θ1 - θ0)
            u = flip_value_direction ? (1 - u) : u

            c_final = sample_vsup_bilinear(vsup_cmap, u, v)

            k += 1
            polys[k] = Point2f[
                Point2f(θ1e, r1),
                Point2f(θ1e, r2),
                Point2f(θ2e, r2),
                Point2f(θ2e, r1),
            ]
            colors[k] = c_final
        end
    end

    poly!(ax, polys;
        color = colors,
        strokewidth = 0,
        strokecolor = :transparent,
    )

    ax.thetaticks = (
        range(θ0, θ1; length = length(value_labels)),
        value_labels,
    )

    ax.rticks = (
        range(1, 0; length = length(uncert_labels)),
        uncert_labels,
    )

    ax.rgridvisible = false
    ax.thetagridvisible = false

    Makie.tightlimits!(ax)
    return ax
end
#= 
begin
    colormap_vsp = :berlin
    f = Figure(size = (550, 400))

    alphas_ticks  = round.(collect(range(extrema(vec_uncert)...; length=5)), digits=2)
    value_labels  = reverse(string.(round.([minimum(vec_estimate), median(vec_estimate), maximum(vec_estimate)], digits=2)))
    uncert_labels = reverse(string.(alphas_ticks))  # outer→inner

    vsp_axis = PolarAxis(f[1:4, 3:4]; width=250, height=220,
        thetalimits = (-π/5, π/5), theta_0 = π/2,
        thetaticklabelsize = 20, rticklabelsize = 20)

    vsup_cmap = vsup_colormatrix(; 
        cmap = cgrad(colormap_vsp), n_uncertainty = 4, 
        max_desat = 0.8, pow_desat = 1.0, max_light = 0.7, pow_light = 1
    )

    vsp_polar_legend_continuous!(vsp_axis;
        vsup_cmap = vsup_cmap,
        value_labels = value_labels,
        uncert_labels = uncert_labels,
    )

 #=    vsp_polar_legend_continuous!(vsp_axis;
        cmap = cgrad(colormap_vsp),
        value_labels = value_labels,
        uncert_labels = uncert_labels,
        thetalims = (-π/5, π/5),
        theta0 = π/2,
        fade_to_gray = false,
    )
 =#
    f
end


 =#
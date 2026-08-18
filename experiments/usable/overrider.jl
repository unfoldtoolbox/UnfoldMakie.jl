
using GeometryBasics: Point2f, Rect2f, decompose

#= ---------------------------------------------------------------------
# Helpers outside Makie.plot!()
# --------------------------------------------------------------------- =#

# -- Handle the nothing/bool/attribute situation for e.g. contours/label_scatter
plot_or_defaults(value::Bool, defaults, name) = value ? defaults : nothing
plot_or_defaults(value::Attributes, defaults, name) = merge(value, defaults)

function plot_or_defaults(value, defaults, name)
    return error("Attribute $(name) has the wrong type: $(typeof(value)).
                 Use either a bool to enable/disable plotting with default attributes,
                 or a NamedTuple with attributes getting passed down to the plot command.")
end

macro plot_or_defaults(var, defaults)
    return :(plot_or_defaults($(esc(var)), $(esc(defaults)), $(QuoteNode(var))))
end

include("../usable/overrider_bivariate.jl")
include("../usable/overrider_contours.jl")
# -----------------------------------------------------------------------------
# Fallback bivariate config (because eeg_topoplot! does NOT forward bivariate=...)
# -----------------------------------------------------------------------------
const _BIVAR_FALLBACK = (
    colorbox      = Ref{Any}(nothing),
    norm_method   = Ref{Symbol}(:ecdf),
    norm_qrange   = Ref{Any}((0.02, 0.98)),
    norm_flip_v   = Ref{Bool}(false),
    norm_bounds_u = Ref{Any}(nothing),
    norm_bounds_v = Ref{Any}(nothing),
    sample_mode   = Ref{Symbol}(:nearest),
)
const _BIVAR_FALLBACK_CONTOURS = Ref{Any}(nothing)


"""
    set_topoplot_bivariate!(; colorbox, norm_method, norm_qrange, norm_flip_v,
                              norm_bounds_u, norm_bounds_v, sample_mode, contours)

Fallback configuration for bivariate topoplots when TopoPlots.eeg_topoplot!
doesn't forward `bivariate=(...)` to the inner `TopoPlot`.
Call this right before plotting.
"""
function set_topoplot_bivariate!(;
    colorbox,
    norm_method::Symbol = :ecdf,
    norm_qrange = (0.02, 0.98),
    norm_flip_v::Bool = false,
    norm_bounds_u = nothing,
    norm_bounds_v = nothing,
    sample_mode::Symbol = :nearest,
    contours = nothing,
)
    _BIVAR_FALLBACK.colorbox[]      = colorbox
    _BIVAR_FALLBACK.norm_method[]   = norm_method
    _BIVAR_FALLBACK.norm_qrange[]   = norm_qrange
    _BIVAR_FALLBACK.norm_flip_v[]   = norm_flip_v
    _BIVAR_FALLBACK.norm_bounds_u[] = norm_bounds_u
    _BIVAR_FALLBACK.norm_bounds_v[] = norm_bounds_v
    _BIVAR_FALLBACK.sample_mode[]   = sample_mode

    _BIVAR_FALLBACK_CONTOURS[]      = contours
    return
end


# -- Observables / grid -------------------------------------------------

@inline Obs(x) = Observable(x; ignore_equal_values = true)

@inline Obs(x) = Observable(x; ignore_equal_values = true)

# keep callback handles alive (recipe plots don't reliably keep fields)
const _TOPO_CB_HANDLE = IdDict{Any, Any}()

function setup_positions_and_geometry(p)
    positions = lift(identity, p, p.positions; ignore_equal_values = true)

    geometry = lift(enclosing_geometry, p, p.bounding_geometry, positions, p.enlarge;
        ignore_equal_values = true)

    # create xg/yg with placeholders
    xg = Obs(LinRange(0.0f0, 1.0f0, p.interp_resolution[][1]))
    yg = Obs(LinRange(0.0f0, 1.0f0, p.interp_resolution[][2]))

    # ✅ IMPORTANT: initialize once immediately (no callbacks needed)
    let g = to_value(geometry), res = to_value(p.interp_resolution)
        (xmin, ymin), (xmax, ymax) = extrema(g)
        xg[] = LinRange(Float32(xmin), Float32(xmax), res[1])
        yg[] = LinRange(Float32(ymin), Float32(ymax), res[2])
    end

    # ✅ IMPORTANT: keep updated AND keep handle alive
    cb = onany(geometry, p.interp_resolution) do g, res
        (xmin, ymin), (xmax, ymax) = extrema(g)
        xg[] = LinRange(Float32(xmin), Float32(xmax), res[1])
        yg[] = LinRange(Float32(ymin), Float32(ymax), res[2])
        return
    end
    _TOPO_CB_HANDLE[p] = cb

    return positions, geometry, xg, yg
end



# -- Mode detection -----------------------------------------------------

is_bivariate_mode(data) =
    (
        data isa Tuple && length(data) == 2 && data[1] isa AbstractVector &&
        data[2] isa AbstractVector
    ) ||
    (
        data isa AbstractVector &&
        (eltype(data) <: Tuple{<:Real,<:Real} || eltype(data) <: NTuple{2,<:Real})
    )

detect_bivariate(p) =
    lift(p, p.data) do data
        is_bivariate_mode(data)
    end

# -- Extrapolation wrapper ----------------------------------------------

function extrapolate_padded(p, is_bivariate)
    lift(p, p.extrapolation, p.positions, p.data) do extrapolation, positions, data
        if to_value(is_bivariate)
            (pts_u, u_bb, _, _) = extrapolation(positions, data[1])
            (pts_v, v_bb, _, _) = extrapolation(positions, data[2])
            @assert length(pts_u) == length(pts_v) "Extrapolation changed lengths for U/V!"
            return (pts_u, (u_bb, v_bb), nothing, nothing)
        else
            return extrapolation(positions, data)
        end
    end
end

# -- Scalar colorrange ---------------------------------------------------

function scalar_colorrange(p, is_bivariate)
    lift(p, p.data, p.colorrange, is_bivariate) do data, crange, isbi
        if isbi
            return nothing
        else
            crange isa Makie.Automatic ? Makie.extrema_nan(data) : crange
        end
    end
end

# -- Mask for regular grid ----------------------------------------------

function make_mask(p, xg, yg, geometry)
    lift(p, xg, yg, geometry) do xg_, yg_, geometry_
        nx = length(xg_)
        ny = length(yg_)

        # your current construction:
        pts = Point2f.(xg_' .* ones(length(yg_)), ones(length(xg_))' .* yg_)
        m = in.(pts, Ref(geometry_))
        # @info "MASK DEBUG" nx=length(xg_) ny=length(yg_) size_pts=size(pts) size_mask=size(m) geom_type=typeof(geometry_) x_first=first(xg_) x_last=last(xg_) y_first=first(yg_) y_last=last(yg_)
        return m
    end
end



# -- Split UV data after extrapolation ----------------------------------

function split_uv_after_extrap(p, padded_pos_data_bb)
    lift(p, padded_pos_data_bb, p.data) do (points, data_bb, _, _), data_orig
        if (
            data_orig isa Tuple && length(data_orig) == 2 &&
            data_orig[1] isa AbstractVector && data_orig[2] isa AbstractVector
        )
            u_bb, v_bb = data_bb
            return (points, Float32.(u_bb), Float32.(v_bb))
        else
            u = Vector{Float32}(undef, length(data_bb))
            v = Vector{Float32}(undef, length(data_bb))
            @inbounds for i in eachindex(data_bb)
                u[i] = Float32(data_bb[i][1])
                v[i] = Float32(data_bb[i][2])
            end
            return (points, u, v)
        end
    end
end

# -- Interpolation for each channel -------------------------------------


interpolate_channel(p, xg, yg, mask, uv_split, which::Symbol) =
lift(p, p.interpolation, xg, yg, uv_split, mask) do interpolation, xg_, yg_, (points, u, v), mask_
    val = (which === :U) ? u : v
    out = interpolation(xg_, yg_, points, val; mask = mask_)
   # @info "INTERP DEBUG" which nx=length(xg_) ny=length(yg_) size_out=size(out)
    return out
end

# -- Reference samples for ECDF -----------------------------------------

function pm_refs_for_ecdf(p)
    lift(p, p.data) do data
        if (
            data isa Tuple && length(data) == 2 &&
            data[1] isa AbstractVector && data[2] isa AbstractVector
        )
            us = Float32.(data[1])
            vs = Float32.(data[2])
        else
            us = Float32[d[1] for d in data]
            vs = Float32[d[2] for d in data]
        end
        (filter(isfinite, us), filter(isfinite, vs))
    end
end

# -- Bivariate options pickup -------------------------------------------

@inline function get_bivar_opt_val(p, key, default)
    biv = get(p.attributes, :bivariate, nothing)
    if biv isa Attributes
        return to_value(get(biv, key, default))
    else
        # fallback (because eeg_topoplot! doesn't forward bivariate=...)
        if key === :colorbox
            return _BIVAR_FALLBACK.colorbox[]
        elseif key === :norm_method
            return _BIVAR_FALLBACK.norm_method[]
        elseif key === :norm_qrange
            return _BIVAR_FALLBACK.norm_qrange[]
        elseif key === :norm_flip_v
            return _BIVAR_FALLBACK.norm_flip_v[]
        elseif key === :norm_bounds_u
            return _BIVAR_FALLBACK.norm_bounds_u[]
        elseif key === :norm_bounds_v
            return _BIVAR_FALLBACK.norm_bounds_v[]
        elseif key === :sample_mode
            return _BIVAR_FALLBACK.sample_mode[]
        else
            return default
        end
    end
end

function bivar_options(p)
    colorbox      = get_bivar_opt_val(p, :colorbox, nothing)
    norm_method   = get_bivar_opt_val(p, :norm_method, :ecdf)
    norm_qrange   = get_bivar_opt_val(p, :norm_qrange, (0.02, 0.98))
    norm_flip_v   = get_bivar_opt_val(p, :norm_flip_v, false)
    norm_bounds_u = get_bivar_opt_val(p, :norm_bounds_u, nothing)
    norm_bounds_v = get_bivar_opt_val(p, :norm_bounds_v, nothing)
    sample_mode   = get_bivar_opt_val(p, :sample_mode, :nearest)

    return (; colorbox, norm_method, norm_qrange, norm_flip_v,
            norm_bounds_u, norm_bounds_v, sample_mode)
end

# -- Bivariate normalization --------------------------------------------

function normalize_uv_obs(p, U, V, pm_refs, opts)
    lift(p, U, V, pm_refs) do U_, V_, (uref, vref)
        normalize_bivariate(U_, V_, uref, vref;
            method = opts.norm_method,
            qrange = opts.norm_qrange,
            fixed_u = opts.norm_bounds_u,
            fixed_v = opts.norm_bounds_v,
            flip_v = opts.norm_flip_v)
    end
end

# -- Render bivariate image ---------------------------------------------

function render_bivariate_image(p, UVnorm, opts)
    cb = opts.colorbox
    cb === nothing && error("Bivariate mode, but no colorbox available. Call set_topoplot_bivariate!(; colorbox=...) before plotting, or forward bivariate.colorbox somehow.")

    lift(p, UVnorm) do UVn
        U01, V01 = UVn[1], UVn[2]
        nx, ny = size(U01)
        out = Array{RGBA{Float32}}(undef, nx, ny)
        mode = opts.sample_mode

        @inbounds for i in axes(U01, 1), j in axes(U01, 2)
            u = U01[i, j]
            v = V01[i, j]
            out[i, j] =
                (isfinite(u) && isfinite(v)) ? sample_bivariate(cb, u, v; mode = mode) :
                RGBA{Float32}(0, 0, 0, 0)
        end
        out
    end
end

# -- Endpoints for image! (Makie deprecation fix) -----------------------

x_interval(xg) =
    lift(xg) do xs
        xs[1] .. xs[end]
    end
y_interval(yg) =
    lift(yg) do ys
        ys[1] .. ys[end]
    end

# -- Scalar interpolation & drawing -------------------------------------

function interpolate_scalar(p, xg, yg, padded_pos_data_bb, mask)
    lift(
        p,
        p.interpolation,
        xg,
        yg,
        padded_pos_data_bb,
        mask,
    ) do interpolation, xg_, yg_, (points, data, _, _), mask_
        interpolation(xg_, yg_, points, data; mask = mask_)
    end
end

function draw_scalar_field!(p, xg, yg, data, colorrange)
    kwargs_all = Dict(
        :colorrange => colorrange,
        :colormap => p.colormap,
        :interpolate => true,
    )
    p.plotfnc![](p, xg, yg, data;
        (
            p.plotfnc_kwargs_names[] .=>
                getindex.(Ref(kwargs_all), p.plotfnc_kwargs_names[])
        )...)
end


# -- Electrode color computation (bivariate & scalar) -------------------

function electrode_colors_bivariate(p, UVnorm, opts)
    cb = opts.colorbox
    cb === nothing && error("Bivariate electrodes need colorbox. Call set_topoplot_bivariate!(; colorbox=...) before plotting.")

    lift(p, p.data, UVnorm) do data, UVn
        Uinfo = UVn[3]
        Vinfo = UVn[4]  # ECDF refs (len>2) or [min,max]

        uvec, vvec = if data isa Tuple && length(data) == 2
            (Float32.(data[1]), Float32.(data[2]))
        else
            (Float32[d[1] for d in data], Float32[d[2] for d in data])
        end

        map_with = function (info, x)
            if length(info) > 2
                Float32(searchsortedlast(info, x) / length(info))
            else
                Float32(clamp((x - info[1]) / max(info[2] - info[1], eps(Float32)), 0, 1))
            end
        end

        flip_v = opts.norm_flip_v
        mode   = opts.sample_mode

        cs = Vector{RGBA{Float32}}(undef, length(uvec))
        @inbounds for i in eachindex(uvec)
            u01 = map_with(Uinfo, uvec[i])
            v01 = map_with(Vinfo, vvec[i])
            v01 = flip_v ? 1 - v01 : v01
            cs[i] =
                (isfinite(u01) && isfinite(v01)) ? sample_bivariate(cb, u01, v01; mode = mode) :
                RGBA{Float32}(0, 0, 0, 0)
        end
        cs
    end
end

# -- Labels --------------------------------------------------------------

function draw_labels_if_any!(p)
    if !isnothing(p.labels[])
        label_text = to_value(p.label_text)
        attributes = @plot_or_defaults label_text Attributes(align = (:right, :top))
        if !isnothing(attributes)
            text!(p, p.positions; text = p.labels, attributes...)
        end
    end
end

#= ---------------------------------------------------------------------
# Branches (bivariate / scalar) — composed from helpers above
# --------------------------------------------------------------------- =#

function draw_bivariate_path!(p, xg, yg, geometry, padded_pos_data_bb, mask)
    uv_split = split_uv_after_extrap(p, padded_pos_data_bb)
    U = interpolate_channel(p, xg, yg, mask, uv_split, :U)
    V = interpolate_channel(p, xg, yg, mask, uv_split, :V)

 
    pm_refs = pm_refs_for_ecdf(p)

    opts = bivar_options(p)
    UVnorm = normalize_uv_obs(p, U, V, pm_refs, opts)
    img = render_bivariate_image(p, UVnorm, opts)
    x_end = x_interval(xg)
    y_end = y_interval(yg)
    
    image!(p, x_end, y_end, img)

    # Optional “contours” via color edges
    contours_toggle = to_value(p.contours)  # bool/Attributes/nothing
    _attrs = @plot_or_defaults contours_toggle Attributes(color = (:black, 0.5),
        linestyle = :dot, levels = 6)
    if !isnothing(_attrs) && !(p.interpolation[] isa NullInterpolator)
        copt = bivar_contours_options(p)  # reads bivariate.contours = (lab_bins=..., color=..., ...)
        draw_bivariate_contours!(p, img, x_end, y_end, copt.nL, copt.nA, copt.nB,
            copt.color, copt.linealpha, copt.linewidth, copt.linestyle)
    end

    return (UVnorm, opts)
end

function draw_scalar_path!(p, xg, yg, padded_pos_data_bb, mask, colorrange)
    data = interpolate_scalar(p, xg, yg, padded_pos_data_bb, mask)
    draw_scalar_field!(p, xg, yg, data, colorrange)
    draw_scalar_contours_if_any!(p, xg, yg, data)
    return nothing
end

#= ---------------------------------------------------------------------
# Final public method
# --------------------------------------------------------------------- =#

function Makie.plot!(p::TopoPlot)
    # Setup
    positions, geometry, xg, yg = setup_positions_and_geometry(p)
    p.geometry = geometry[]
    is_bivariate = detect_bivariate(p)
    padded_pos_data_bb = extrapolate_padded(p, is_bivariate)
    colorrange = scalar_colorrange(p, is_bivariate)

    if p.interpolation[] isa DelaunayMesh
        # Scalar mesh path (bivariate via Delaunay not supported)
        m = lift(p, positions) do pos
            TopoPlots.delaunay_mesh(pos)
        end
        mesh!(
            p,
            m;
            color = p.data,
            colorrange = colorrange,
            colormap = p.colormap,
            shading = NoShading,
        )
    else
        mask = make_mask(p, xg, yg, geometry)
        UVnorm_or_nothing = nothing
        opts = nothing

        if to_value(is_bivariate)
            UVnorm_or_nothing, opts = draw_bivariate_path!(p, xg, yg, geometry, padded_pos_data_bb, mask)
        else
            draw_scalar_path!(p, xg, yg, padded_pos_data_bb, mask, colorrange)
        end

        # Electrode markers
        label_scatter = to_value(p.label_scatter)
        attributes = @plot_or_defaults label_scatter Attributes(
            markersize = p.markersize,
            colormap = p.colormap,
            colorrange = colorrange,
            strokecolor = :black,
            strokewidth = 1,
        )

        if !isnothing(attributes)
            if to_value(is_bivariate)
                elec_colors = electrode_colors_bivariate(p, UVnorm_or_nothing, opts)
                scatter!(p, p.positions; color = elec_colors, attributes...)
            else
                scatter!(p, p.positions; color = p.data, colormap = p.colormap,
                    colorrange = colorrange, attributes...)
            end
        end

        # Labels
        draw_labels_if_any!(p)
    end

    return
end

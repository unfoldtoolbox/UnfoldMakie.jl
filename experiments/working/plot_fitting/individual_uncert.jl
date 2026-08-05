using Base: padding
using UnfoldSim
using LinearAlgebra
using ColorSchemes
using Colors
using Animations
using Printf
using Random
include("../plot_helpers/bivariate_maps.jl")
include("../plot_helpers/overrider.jl")
include("../plot_helpers/overrider_bivariate.jl")
include("../plot_helpers/vsp_sup.jl")

# -----------------------------------------------------------------------------
# Shared scalar helpers
# -----------------------------------------------------------------------------

# test = load_erp_subject("P3"; subject=11, timepoint=128, condition=1)
_shared_colormap = cgrad(:RdBu, 10; categorical = true, rev = true)

function _scalar_topoplot_visual(;
    colormap,
    colorrange_mode = :diverging_balanced,
    kwargs...,
)
    return (;
        colormap = colormap,
        colorrange_mode = colorrange_mode,
        kwargs...,
    )
end

function _shared_scalar_topoplot_range(arrays...; colorrange_mode = :diverging_balanced)
    vals = reduce(vcat, [collect(skipmissing(vec(arr))) for arr in arrays])
    return UnfoldMakie._topo_range_from_values(vals; colorrange_mode = colorrange_mode)
end

function _resolved_scalar_colormap(colormap; colorrange_mode = :diverging_balanced)
    resolved_visual = UnfoldMakie.topo_resolved_visual((;
        colormap = colormap,
        colorrange_mode = colorrange_mode,
    ))
    return resolved_visual.colormap
end

_tick_label_1dp(x) = @sprintf("%.1f", Float64(x))
_tick_labels_1dp(values) = _tick_label_1dp.(values)
_tick_label_ndp(x, digits) = @sprintf("%.*f", digits, Float64(x))

function _distinct_tick_labels(values; min_digits = 1, max_digits = 4)
    for digits in min_digits:max_digits
        labels = [_tick_label_ndp(v, digits) for v in values]
        length(unique(labels)) == length(labels) && return labels
    end
    [_tick_label_ndp(v, max_digits) for v in values]
end

function _scalar_colorbar_ticks(lims; colorrange_mode = :diverging_balanced)
    lo, hi = Float32.(lims)
    pos = if colorrange_mode == :sequential
        Float32.(collect(LinRange(lo, hi, 5)))
    else
        Float32[lo, lo / 2, 0f0, hi / 2, hi]
    end
    lab =
        colorrange_mode == :sequential ?
        _distinct_tick_labels(pos; min_digits = 2, max_digits = 4) :
        _tick_labels_1dp(pos)
    return (pos, lab)
end


# -----------------------------------------------------------------------------
# Adjacent scalar topoplots
# -----------------------------------------------------------------------------

function plot_adjacent!(
    f::Union{GridPosition, GridLayout, Figure},
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    enable_contour=true,
    uncert_label="Uncertainty",
    BG=:white,
    colorrange_mode = :diverging_balanced,
    colorbar_labelsize = 24,
    colorbar_ticklabelsize = 18,
    colorbar_width = 180,
    axis_labelsize = 24,
)
    gl = f isa GridLayout ? f : f isa Figure ? (f[1, 1] = GridLayout()) : (f[] = GridLayout())
    estimate_lims = _shared_scalar_topoplot_range(vec_estimate; colorrange_mode = colorrange_mode)
    uncert_lims = _shared_scalar_topoplot_range(vec_uncert; colorrange_mode = colorrange_mode)

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                (;)

    plot_topoplot!(
        gl[1, 1],
        vec_estimate;
        topo_args...,
        visual = _scalar_topoplot_visual(;
            contours = enable_contour,
            clip = false,
            colormap = _shared_colormap,
            colorrange_mode = colorrange_mode,
        ),
        axis = (;
            xlabel = "",
            xautolimitmargin = (0.02, 0.02),
            yautolimitmargin = (0.03, -0.01),
        ),
        topo_axis = (; backgroundcolor = BG),
        colorbar = (;
            label = "Voltage [µV]",
            labelsize = colorbar_labelsize,
            ticklabelsize = colorbar_ticklabelsize,
            ticks = _scalar_colorbar_ticks(estimate_lims; colorrange_mode = colorrange_mode),
            vertical = false,
            position = :bottom,
            width = colorbar_width,
        ),
    )

    plot_topoplot!(
        gl[1, 2],
        vec_uncert;
        topo_args...,
        visual = _scalar_topoplot_visual(;
            colormap = :viridis,
            contours = enable_contour,
        ),
        axis = (;
            xlabel = "",
            xlabelsize = axis_labelsize,
            ylabelsize = axis_labelsize,
        ),
        topo_axis = (; backgroundcolor = BG),
        colorbar = (;
            label = uncert_label,
            labelsize = colorbar_labelsize,
            ticklabelsize = colorbar_ticklabelsize,
            #ticks = _scalar_colorbar_ticks(uncert_lims; colorrange_mode = colorrange_mode),
            vertical = false,
            position = :bottom,
            width = colorbar_width,
        ),
    )

    return gl
end

function plot_adjacent(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_adjacent!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

#= 
test = load_erp_subject("MMN"; subject=20, timepoint=96, condition=1)
plot_adjacent(test.estimate, test.se; labels = test.labels, uncert_label = "SE")
 =#


# -----------------------------------------------------------------------------
# Bivariate corner plot
# -----------------------------------------------------------------------------

# Palettes and helpers for `plot_bivariate_corner!`.
_colorbox_corner = [
    colorant"#1F99DC"  colorant"#92B6CA"  colorant"#D0D4B6"  colorant"#86BD9B"  colorant"#19A381";
    colorant"#7294B3"  colorant"#A5B3B5"  colorant"#D2D4B6"  colorant"#9FB79F"  colorant"#6A9A89";
    colorant"#909190"  colorant"#B2B1A3"  colorant"#D4D3B6"  colorant"#B2B1A3"  colorant"#919190";
    colorant"#A28E72"  colorant"#BCB093"  colorant"#D6D3B6"  colorant"#C2ACA6"  colorant"#AD8697";
    colorant"#AD8B58"  colorant"#C3AE86"  colorant"#D7D2B7"  colorant"#CEA7A9"  colorant"#C27B9C"
]

_colorbox_corner_2 = [
    colorant"#1F99DC"  colorant"#92B6CA"  colorant"#D0D4B6"  colorant"#86BD9B"  colorant"#19A381";
    colorant"#7294B3"  colorant"#A5B3B5"  colorant"#D0D4B6"  colorant"#9FB79F"  colorant"#6A9A89";
    colorant"#909190"  colorant"#B2B1A3"  colorant"#D0D4B6"  colorant"#B2B1A3"  colorant"#919190";
    colorant"#A28E72"  colorant"#BCB093"  colorant"#D0D4B6"  colorant"#C2ACA6"  colorant"#AD8697";
    colorant"#AD8B58"  colorant"#C3AE86"  colorant"#D0D4B6"  colorant"#CEA7A9"  colorant"#C27B9C"
]

_colorbox_corner_3 = copy(_colorbox_corner_2)
_colorbox_corner_3[:, 4] = reverse(_colorbox_corner_3[:, 4])
_colorbox_corner_3[:, 5] = reverse(_colorbox_corner_3[:, 5])

_colorbox_corner_bremm = [
    colorant"#04F79B" colorant"#1EED4D" colorant"#60D052" colorant"#BE809D" colorant"#F62FC9";
    colorant"#0CDAE2" colorant"#54C19B" colorant"#86A580" colorant"#BA7886" colorant"#F1396C";
    colorant"#15A9F6" colorant"#6A99B8" colorant"#949097" colorant"#BC7E6D" colorant"#F7442A";
    colorant"#196FF9" colorant"#6A7ACA" colorant"#978A9C" colorant"#C38F5B" colorant"#F9730E";
    colorant"#1A2FFC" colorant"#6759DB" colorant"#9D83A4" colorant"#CBAF48" colorant"#F8C106";
]


_colorbox_corner_teuling = [
    colorant"#2E98FE" colorant"#6893FF" colorant"#9482FC" colorant"#AF5FE2" colorant"#BD2EBB";
    colorant"#55C7F0" colorant"#97CCFE" colorant"#CAC1FD" colorant"#DE98DD" colorant"#E35EAC";
    colorant"#6EEAD4" colorant"#B7F4E8" colorant"#FDFEFA" colorant"#FEC0C7" colorant"#FC8191";
    colorant"#75FBA7" colorant"#B7FFB4" colorant"#E9F3B2" colorant"#FECB93" colorant"#FF9264";
    colorant"#6FFF6C" colorant"#A9FA71" colorant"#D4E869" colorant"#EFC64F" colorant"#FE9629"
]

_colorbox_corner_teuling2 = [
    colorant"#0099DE" colorant"#638EF7" colorant"#9482FC" colorant"#AF5FE2" colorant"#BD2EBB";
    colorant"#55C7F0" colorant"#97CCFE" colorant"#CAC1FD" colorant"#DE98DD" colorant"#E35EAC";
    colorant"#6EEAD4" colorant"#B7F4E8" colorant"#FDFEFA" colorant"#FEC0C7" colorant"#FC8191";
    colorant"#75FBA7" colorant"#B7FFB4" colorant"#E9F3B2" colorant"#FECB93" colorant"#FF9264";
    colorant"#6FFF6C" colorant"#A9FA71" colorant"#D4E869" colorant"#EFC64F" colorant"#FE9629"
]

_colorbox_corner_teuling3 = [
    colorant"#009BCB" colorant"#687FF5" colorant"#9482FC" colorant"#AF5FE2" colorant"#BD2EBB";
    colorant"#55C7F0" colorant"#97CCFE" colorant"#CAC1FD" colorant"#DE98DD" colorant"#E35EAC";
    colorant"#6EEAD4" colorant"#B7F4E8" colorant"#FDFEFA" colorant"#FEC0C7" colorant"#FC8191";
    colorant"#75FBA7" colorant"#B7FFB4" colorant"#E9F3B2" colorant"#FECB93" colorant"#FF9264";
    colorant"#6FFF6C" colorant"#A9FA71" colorant"#D4E869" colorant"#EFC64F" colorant"#FE9629"
]


function _draw_absent_colorbox_hatching!(ax, occupied; linewidth = 1.4, color = :black)
    n_rows, n_cols = size(occupied)
    @inbounds for row in 1:n_rows, col in 1:n_cols
        occupied[row, col] && continue
        lines!(
            ax,
            [col - 0.42, col + 0.42],
            [row - 0.42, row + 0.42];
            color = color,
            linewidth = linewidth,
        )
    end
    ax
end

function plot_bivariate_corner!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "SD",
    colorrange_mode = :diverging_balanced,
    order_vertical = :low_to_high,
    wireframe = false,
    hatch = true,
    show_colorbox = true,
    colorbox = nothing,
    topo_size = nothing,
    colorbox_size = 130,
    axis_labelsize = 16,
    axis_ticklabelsize = 12,
    colorbox_gap = 5,
    BG = :white,
)
    gl = f isa Figure ? f.layout :
         f isa GridLayout ? f :
         (f[] = GridLayout())
    colorbox = isnothing(colorbox) ?
        (colorrange_mode == :sequential ? _colorbox_corner_sequential : _colorbox_corner_teuling3) :
        colorbox
    n_rows, n_cols = size(colorbox)
    norm_method = :robust_minmax
    norm_qrange = (0.005, 0.995)
    norm_flip_v = false
    
    xticks = collect(range(
        UnfoldMakie._topo_range_from_values(
            vec_estimate;
            colorrange_mode = colorrange_mode,
        )...;
        length = n_cols,
    ))
    yticks = collect(range(extrema(vec_uncert)...; length = n_rows))

    label_inds_x = [1, 3, n_cols]
    label_inds_y = [1, 3, n_rows]
    xticks_label = [
        i in label_inds_x ? _tick_label_1dp(vec_estimate) : "" for
        (i, vec_estimate) in enumerate(xticks)
    ]
    yticks_label = [
        i in label_inds_y ? _tick_label_1dp(vec_uncert) : "" for
        (i, vec_uncert) in enumerate(yticks)
    ]
    colorbox_ax = nothing

    if show_colorbox
        colorbox_ax = Axis(
            gl[1, 2],
            aspect = DataAspect(),
            xlabel = "Voltage [µV]", ylabel = uncert_label, title = "",
            xlabelsize = axis_labelsize, ylabelsize = axis_labelsize,
            xticklabelsize = axis_ticklabelsize,
            yticklabelsize = axis_ticklabelsize,
            ylabelpadding = 0,
            xticks = (collect(1:n_cols), xticks_label),
            yticks = (collect(1:n_rows), yticks_label),
            width = colorbox_size, height = colorbox_size,
            backgroundcolor = BG,
        )

        heatmap!(colorbox_ax, colorbox'; colormap = vec(colorbox))

        if wireframe
            for x in 0.5:1:(n_cols + 0.5)
                lines!(colorbox_ax, [x, x], [0.5, n_rows + 0.5];
                    color = (:black, 1),
                    linewidth = 0.8,
                )
            end

            for y in 0.5:1:(n_rows + 0.5)
                lines!(colorbox_ax, [0.5, n_cols + 0.5], [y, y];
                    color = (:black, 1),
                    linewidth = 0.8,
                )
            end
        end
        hidedecorations!(colorbox_ax, label = false, ticks = false, ticklabels = false)
        hidespines!(colorbox_ax)
    end

    topo_axis = Axis(
        gl[1, 1],
        aspect = DataAspect(),
        xlabel = "",
        width = topo_size, height = topo_size,
        limits = (-1.25, 1.25, -1.25, 1.2),
        backgroundcolor = BG,
    )

    set_topoplot_bivariate!(;
        colorbox     = colorbox,
        norm_method  = norm_method,
        norm_qrange  = norm_qrange,
        norm_flip_v  = norm_flip_v,
        sample_mode  = :nearest,
    )
    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                (;)

    topo_plot = TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        topo_args...,
        contours = true,
    )
    if hatch && show_colorbox && !isnothing(colorbox_ax)
        # Match hatching to the interpolated topoplot that is actually shown.
        occupied = topo_plot.plots[1].bivariate_occupied_bins[]
        _draw_absent_colorbox_hatching!(colorbox_ax, occupied)
    end
    hidedecorations!(topo_axis, label = false); hidespines!(topo_axis)
    show_colorbox && colgap!(gl, colorbox_gap)
    return gl
end


function plot_bivariate_corner(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_bivariate_corner!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

# Scratch examples for `plot_bivariate_corner!` (expects `test` in scope).
#=
plot_bivariate_corner(test.estimate, test.se; labels = test.labels, uncert_label = "SE")
plot_bivariate_corner(
    test.estimate,
    test.se;
    labels = test.labels,
    uncert_label = "SE",
    colorbox = reverse(_colorbox_corner_bremm, dims = 1),
)
plot_bivariate_corner(
    test.estimate,
    test.se;
    labels = test.labels,
    uncert_label = "SE",
    colorbox = _colorbox_corner_teuling,
)

begin
    f = Figure(size = (500, 300), figure_padding = (0, 0, -20, 10))
    plot_bivariate_corner!(
        f,
        test.estimate,
        test.se;
        labels = test.labels,
        uncert_label = "SE",
        colorbox = _colorbox_corner_2,
    )
    f
end
=#


# -----------------------------------------------------------------------------
# Bivariate range plot
# -----------------------------------------------------------------------------

# Palettes and helpers for `plot_bivariate_range!`.
_colorbox_range = [
    colorant"#5D92DD"  colorant"#94B7BA"  colorant"#D5D597"  colorant"#E4A36F"  colorant"#ED673E";
    colorant"#7092CA"  colorant"#9BB5B8"  colorant"#D4D4A8"  colorant"#DAA67E"  colorant"#DB7452";
    colorant"#7C91BA"  colorant"#A2B4B6"  colorant"#D4D4B4"  colorant"#D0A98D"  colorant"#CA7D64";
    colorant"#8591AB"  colorant"#A7B3B4"  colorant"#D3D3BE"  colorant"#C6AC99"  colorant"#B88574";
    colorant"#8B919F"  colorant"#ACB2B2"  colorant"#D2D2C7"  colorant"#BCAEA4"  colorant"#A78B81"
]

_colorbox_range_2 = [
    colorant"#5D92DD"  colorant"#94B7BA"  colorant"#D5D597"  colorant"#E4A36F"  colorant"#ED673E";
    colorant"#7092CA"  colorant"#9BB5B8"  colorant"#D5D597"  colorant"#DAA67E"  colorant"#DB7452";
    colorant"#7C91BA"  colorant"#A2B4B6"  colorant"#D5D597"  colorant"#D0A98D"  colorant"#CA7D64";
    colorant"#8591AB"  colorant"#A7B3B4"  colorant"#D5D597"  colorant"#C6AC99"  colorant"#B88574";
    colorant"#8B919F"  colorant"#ACB2B2"  colorant"#D5D597"  colorant"#BCAEA4"  colorant"#A78B81"
]

_colorbox_range_2_light = [
    colorant"#5D92DD"  colorant"#94B7BA"  colorant"#D5D597"  colorant"#E4A36F"  colorant"#ED673E";
    colorant"#8AA6DB"  colorant"#B3CBCD"  colorant"#EBEAC0"  colorant"#EDBD99"  colorant"#ED8C6D";
    colorant"#ABBCE0"  colorant"#D0E0E1"  colorant"#FCFBDE"  colorant"#F9D7BE"  colorant"#F0AB94";
    colorant"#C7D2EA"  colorant"#EBF6F7"  colorant"#FBFAE7"  colorant"#FFF0DF"  colorant"#F7C7B7";
    colorant"#E2E8F7"  colorant"#F4FBFB"  colorant"#FBFAEE"  colorant"#FFF7ED"  colorant"#FFE2D8"
]
@inline function _range_seq_lch(c::Colorant, L::Real; chroma_scale::Real = 1.0)
    lch = convert(LCHab, RGB(c))
    H = isnan(lch.h) ? 0.0 : Float64(lch.h)
    return RGB{Float32}(LCHab(
        clamp(Float64(L), 0.0, 100.0),
        clamp(lch.c * Float64(chroma_scale), 0.0, 120.0),
        H,
    ))
end

function _make_colorbox_range_sequential(;
    n_rows::Int = 5,
    n_cols::Int = 5,
    colormap = :viridis,
    L_left::Real = 18,
    L_right::Real = 88,
    chroma_top::Real = 1.0,
    chroma_bottom::Real = 0.12,
    lightness_top::Real = 0.0,
    lightness_bottom::Real = 16.0,
)
    grad = cgrad(colormap)
    ts = range(0.0, 1.0; length = n_cols)
    base_cols = RGB{Float32}.(get.(Ref(grad), ts))

    L_cols = collect(range(float(L_left), float(L_right); length = n_cols))
    chroma_rows = collect(range(float(chroma_top), float(chroma_bottom); length = n_rows))
    dL_rows = collect(range(float(lightness_top), float(lightness_bottom); length = n_rows))

    top_row = [_range_seq_lch(base_cols[j], L_cols[j]) for j in 1:n_cols]

    return [
        _range_seq_lch(top_row[j], L_cols[j] + dL_rows[i]; chroma_scale = chroma_rows[i])
        for i in 1:n_rows, j in 1:n_cols
    ]
end

_colorbox_range_sequential = _make_colorbox_range_sequential()

function plot_bivariate_range!(
    f::Union{GridPosition, GridLayout, Figure},
    vec_estimate,
    vec_uncert;
    positions=nothing,
    labels=nothing,
    n_cb=5,
    uncert_label="Uncertainty",
    order_vertical = :low_to_high,
    wireframe = false,
    hatch = true,
    enable_contour=true,
    colorrange_mode = :diverging_balanced,
    colorbox = nothing,
    topo_size = nothing,
    colorbox_size = 130,
    axis_labelsize = 16,
    axis_ticklabelsize = 12,
    colorbox_gap = 5,
    BG = :white,
)
    gl = f isa Figure ? f.layout :
         f isa GridLayout ? f :
         (f[] = GridLayout())

    colorbox = isnothing(colorbox) ?
        (colorrange_mode == :sequential ? _colorbox_range_sequential : _colorbox_range_2_light) :
        colorbox
    n_rows, n_cols = size(colorbox)

    norm_qrange = (0.005, 0.995)

    function quantile_label_range(values, qrange)
        vals = collect(filter(isfinite, values))
        isempty(vals) && return Float32.((0, 1))
        return Float32.(quantile(vals, qrange))
    end

    xticks = collect(range(
        UnfoldMakie._topo_range_from_values(
            vec_estimate;
            colorrange_mode = colorrange_mode,
        )...;
        length = n_cb,
    ))
    yticks = collect(range(quantile_label_range(vec_uncert, norm_qrange)...; length=n_cb))

    label_inds_x = [1, 3, n_cb]
    label_inds_y = [1, 3, n_cb]

    xticks_label = [i in label_inds_x ? _tick_label_1dp(x) : "" for (i, x) in enumerate(xticks)]
    yticks_label = [i in label_inds_y ? _tick_label_1dp(y) : "" for (i, y) in enumerate(yticks)]

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    topo_axis = Axis(
        gl[1, 1],
        aspect = DataAspect(),
        xlabel = "",
        width = topo_size, height = topo_size,
        limits = (-1.25, 1.25, -1.25, 1.2),
        backgroundcolor = BG,
    )

    set_topoplot_bivariate!(;
        colorbox    = colorbox,
        norm_method = :robust_minmax,
        norm_qrange = norm_qrange,
        norm_flip_v = false,
        sample_mode = :nearest,
        contours = (; lab_bins = (16,16,16), linestyle = :dot)
    )

    topo_plot = TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        topo_args...,
        contours = enable_contour,
    )

    hide_axis!(topo_axis)

    ax = Axis(
        gl[1, 2],
        aspect = DataAspect(),
        xlabel = "Voltage [µV]",
        ylabel = uncert_label,
        title = "",
        xlabelsize = axis_labelsize, ylabelsize = axis_labelsize,
        xticklabelsize = axis_ticklabelsize,
        yticklabelsize = axis_ticklabelsize,
        ylabelpadding = 0,
        xticks = (collect(1:n_cb), xticks_label),
        yticks = (collect(1:n_cb), yticks_label),
        width = colorbox_size, height = colorbox_size,
        backgroundcolor = BG,
    )

    heatmap!(ax, colorbox'; colormap = vec(colorbox))
    if hatch
        occupied = topo_plot.plots[1].bivariate_occupied_bins[]
        _draw_absent_colorbox_hatching!(ax, occupied)
    end
    if wireframe == true # wireframe / cell borders
        for x in 0.5:1:(n_cols + 0.5)
            lines!(ax, [x, x], [0.5, n_rows + 0.5];
                color = (:black, 1),
                linewidth = 0.8,
            )
        end

        for y in 0.5:1:(n_rows + 0.5)
            lines!(ax, [0.5, n_cols + 0.5], [y, y];
                color = (:black, 1),
                linewidth = 0.8,
            )
        end
    end
    hidedecorations!(ax, label=false, ticks=false, ticklabels=false)
    hidespines!(ax)
    colgap!(gl, colorbox_gap)
    return gl
end

function plot_bivariate_range(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_bivariate_range!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

# Scratch example for `plot_bivariate_range!` (expects `test` in scope).
# plot_bivariate_range(test.estimate, test.se; labels = test.labels, uncert_label = "SE")


# -----------------------------------------------------------------------------
# VSP plot
# -----------------------------------------------------------------------------

function plot_vsp!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "Uncertainty",
    enable_contour = true,
    reverse_vsp_rows = true,
    colormap_vsp = :RdYlBu,
)
    gl = f isa Figure ? f.layout :
         f isa GridLayout ? f :
         (f[] = GridLayout())
    vec_estimate_c = UnfoldMakie._topo_range_from_values(vec_estimate)

    uncert_labels = _tick_labels_1dp(collect(range(extrema(vec_uncert)...; length = 5)))
    value_labels = reverse(string.(
        Any[
            _tick_label_1dp(minimum(vec_estimate_c)),
            _tick_label_1dp(mean(vec_estimate_c)),
            _tick_label_1dp(maximum(vec_estimate_c)),
        ]
    ))
     
    vsp_axis = PolarAxis(
        gl[2:3, 3:4];
        width = 200, height = 170,
        thetalimits = (-π / 5, π / 5),
        theta_0 = π / 2, thetaticklabelsize = 12, rticklabelsize = 12,
        halign = :right,# clipcolor = :green
    )
    
    vsup_cmap = vsup_colormatrix(;
        cmap = cgrad(colormap_vsp; rev = true), n_uncertainty = 4,
        max_desat = 0.8, pow_desat = 1.0, max_light = 0.7, pow_light = 1,
    )

    vsp_rows = reverse([(vsup_cmap'[:, i]) for i = 1:size(vsup_cmap', 2)])

    norm_flip_v = true
    if !reverse_vsp_rows
        uncert_labels = reverse(uncert_labels)
        norm_flip_v = false
    end

    vsp_polar_legend!(
        vsp_axis;
        vsp_rows = vsp_rows,
        value_labels = value_labels, uncert_labels = uncert_labels,
        thetalims = (-π / 5, π / 5), theta0 = π / 2,
    )
    topo_axis = Axis(
        gl[1:4, 1:2]; aspect = DataAspect(),
        xlabel = "", width = 300, height = 300,
        limits = (-1.25, 1.25, -1.25, 1.2),
    )
    hidedecorations!(topo_axis, label = false); hidespines!(topo_axis)

    set_topoplot_bivariate!(;
        colorbox    = vsp_rows_to_colorbox(vsp_rows),
        norm_method = :robust_minmax,
        norm_qrange = (0.005, 0.995),
        norm_flip_v = norm_flip_v,
        sample_mode = :nearest,
    )

    topo_args =
        positions !== nothing ? (; positions = positions) :
        labels !== nothing    ? (; labels = labels) :
                                error("Either positions or labels must be provided.")

    TopoPlots.eeg_topoplot!(
        topo_axis,
        (vec_estimate, vec_uncert);
        topo_args...,
        contours = enable_contour,
    )


    lx = Label(gl[2:3, 3:4], "Voltage [µV]", tellwidth = false, padding = (100, 0, 160, 0))
    ly = Label(gl[2:3, 3:4], uncert_label, tellheight = false, rotation = pi/3, padding = (0, -210, -80, 0))
    translate!(lx.blockscene, 0, 0, 10_000)
    translate!(ly.blockscene, 0, 0, 10_000)
    translate!(topo_axis.blockscene, 0, 0, 10_000)
    colgap!(gl, -100)
    return gl
end

#= begin
    f = Figure(size = (500, 300), figure_padding = (16, -10, 16, 10))
    plot_vsp!(f, test.estimate, test.se; labels = test.labels, uncert_label = "|t|-value")
    f
end =#

function plot_vsp(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_vsp!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end


# Scratch example for `plot_vsp!` (expects `test` in scope).
# plot_vsp(test.estimate .- 4.55, test.t; labels = test.labels, uncert_label = "|t|-value")


# -----------------------------------------------------------------------------
# Uncertainty marker plot
# -----------------------------------------------------------------------------

function plot_uncert_markers!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "Uncertainty",
    enable_contour = true,
    BG = :white,
    colorrange_mode = :diverging_balanced,
    axis_labelsize = 24,
    colorbar_labelsize = 24,
    colorbar_ticklabelsize = 18,
    colorbar_height = 220,
    legend_labelsize = 18,
    legend_titlesize = 20,
    legend_margin = (24, 10, 0, 0),
    legend_colgap = 5,
    row_gap = -10,
    topo_size = nothing,
)
    gl = f isa GridLayout ? f : f isa Figure ? (f[1, 1] = GridLayout()) : (f[] = GridLayout())

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    uncert_norm =
        (vec_uncert .- minimum(vec_uncert)) ./ (maximum(vec_uncert) - minimum(vec_uncert))
    uncert_scaled = uncert_norm .* 30 .+ 10

    plot_topoplot!(
        gl[1:3, 1],
        vec_estimate;
        topo_args...,
        axis = (; xlabel = "", xlabelsize = axis_labelsize, ylabelsize = axis_labelsize),
        topo_attributes = (;
            label_scatter = (;
                markersize = uncert_scaled,
                color = :transparent,
                strokecolor = :black,
                strokewidth = uncert_scaled .* 0.25,   
            ),
        ),
        topo_axis = (;
            backgroundcolor = BG,
            limits = (-1.25, 1.25, -1.3, 1.15),
            (isnothing(topo_size) ? NamedTuple() : (; width = topo_size, height = topo_size))...,
        ),
        visual = _scalar_topoplot_visual(;
            colormap = _shared_colormap,
            contours = enable_contour,
            colorrange_mode = colorrange_mode,
        ),
        colorbar = (;
            labelsize = colorbar_labelsize,
            ticklabelsize = colorbar_ticklabelsize,
            height = colorbar_height,
            ticks = _scalar_colorbar_ticks(
                _shared_scalar_topoplot_range(vec_estimate; colorrange_mode = colorrange_mode);
                colorrange_mode = colorrange_mode,
            ),
        ),
    )

    markersizes = round.(Int, range(extrema(uncert_scaled)...; length = 5))
    markerlabels = round.(range(extrema(vec_uncert)...; length = 5); digits = 2)

    group_size = [
        MarkerElement(
            marker = :circle,
            color = :transparent,
            strokecolor = :black,
            strokewidth = ms ÷ 5,
            markersize = ms,
        )
        for ms in markersizes
    ]

    Legend(
        gl[4, 1],
        group_size,
        ["$x" for x in markerlabels],
        uncert_label,
        patchsize = (maximum(markersizes) * 0.8, maximum(markersizes) * 0.8),
        framevisible = false,
        labelsize = legend_labelsize,
        titlesize = legend_titlesize,
        orientation = :horizontal,
        titleposition = :left,
        colgap = legend_colgap,
        margin = legend_margin,
        backgroundcolor = BG,
    )
    rowsize!(gl, 1, Relative(0.35))
    rowsize!(gl, 2, Relative(0.3))
    rowsize!(gl, 3, Relative(0.3))
    rowsize!(gl, 4, Auto(0.15))
    rowgap!(gl, row_gap)
    return gl
end

function plot_uncert_markers(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_uncert_markers!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

# Self-contained scratch example for `plot_uncert_markers!`.
#=
begin
    @isdefined(load_erp_subject_avgref_or_nothing) ||
        include("../region_detection/rereferencing.jl")
    subject_data = load_erp_subject_avgref_or_nothing(
        "MMN";
        subject = 1,
        timepoint = 96,
        condition = 3,
    )
    isnothing(subject_data) && error("Missing avgref CSV for MMN_1.")

    f = Figure(size = (500, 300), figure_padding = (16, 16, 16, 10))
    plot_uncert_markers!(
        f,
        avgref_signal(subject_data),
        Float64.(subject_data.se);
        labels = subject_data.labels,
        uncert_label = "SE",
    )
    f
end
=#



# -----------------------------------------------------------------------------
# Triple confidence-interval plot
# -----------------------------------------------------------------------------

function plot_triple_CI!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    uncert_label = "SE",
    BG = :white,
    colorrange_mode = :diverging_balanced,
    enable_contour = false,
    colorbar_labelsize = 24,
    colorbar_ticklabelsize = 12,
    colorbar_height = 240,
    colorbar_gap = nothing,
    topo_rowgap = -50,
    topo_colgap = -90,
    topo_size = 230,
)
    gl = f isa GridLayout ? f : f isa Figure ? (f[1, 1] = GridLayout()) : (f[] = GridLayout())
    topo_axis_cfg = isnothing(topo_size) ?
                    (; backgroundcolor=BG) :
                    (; backgroundcolor=BG, width = topo_size, height = topo_size)

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    pTopos = GridLayout()
    gl[1:2, 1:3] = pTopos

    pA = pTopos[1, 2]
    pB = pTopos[2, 1]
    pC = pTopos[2, 3]
    pcb = gl[:, 4]

    lims = _shared_scalar_topoplot_range(
        vec_estimate,
        vec_estimate .- vec_uncert,
        vec_estimate .+ vec_uncert;
        colorrange_mode = colorrange_mode,
    )

    visual = _scalar_topoplot_visual(;
        limits = lims,
        colormap = _shared_colormap,
        contours = enable_contour,
        colorrange_mode = colorrange_mode,
    )

    ticks5 = _scalar_colorbar_ticks(lims; colorrange_mode = colorrange_mode)
    cb_colormap = _resolved_scalar_colormap(
        _shared_colormap;
        colorrange_mode = colorrange_mode,
    )

    plot_topoplot!(
        pA,
        vec_estimate;
        topo_args...,
        axis = (; backgroundcolor=BG, ylabelsize=16, ylabel="", xlabel=""),
        topo_axis = topo_axis_cfg,
        layout = (; use_colorbar=false),
        visual = visual,
    )

    plot_topoplot!(
        pB,
        vec_estimate .- vec_uncert;
        topo_args...,
        axis = (; backgroundcolor=BG, xlabelsize=20, xlabel="Mean - $uncert_label"),
        topo_axis = topo_axis_cfg,
        visual = visual,
        layout = (; use_colorbar=false),
    )

    plot_topoplot!(
        pC,
        vec_estimate .+ vec_uncert;
        topo_args...,
        topo_axis = topo_axis_cfg,
        axis = (; backgroundcolor=BG, xlabelsize=20, xlabel="Mean + $uncert_label"),
        visual = visual,
        layout = (; use_colorbar=false),
    )

    Colorbar(
        pcb,
        colormap = cb_colormap, limits = lims,
        ticks = ticks5, label = "Voltage [µV]",
        labelsize = colorbar_labelsize,
        ticklabelsize = colorbar_ticklabelsize,
        vertical = true,
        height = colorbar_height,
        flipaxis = true,
        labelrotation = -π/2,
    )

    rowgap!(pTopos, topo_rowgap)
    colgap!(pTopos, topo_colgap)
    rowgap!(gl, 0)
    isnothing(colorbar_gap) || colgap!(gl, 3, colorbar_gap)

    return gl
end

function plot_triple_CI(vec_estimate, vec_uncert; positions=nothing, labels=nothing, kwargs...)
    f = Figure()
    plot_triple_CI!(f, vec_estimate, vec_uncert; positions=positions, labels=labels, kwargs...)
    return f
end

# Self-contained scratch example for function-level `topo_size` control.

#= begin
    @isdefined(load_erp_subject_avgref_or_nothing) ||
        include("../region_detection/rereferencing.jl")
    subject_data = load_erp_subject_avgref_or_nothing(
        "MMN";
        subject = 1,
        timepoint = 96,
        condition = 3,
    )
    isnothing(subject_data) && error("Missing avgref CSV for MMN_1.")

    plot_triple_CI(
        avgref_signal(subject_data),
        Float64.(subject_data.se);
        labels = subject_data.labels,
        uncert_label = "SE",
        topo_size = 230,
        colorbar_gap = 20,
    )
end
 =#




# -----------------------------------------------------------------------------
# HOP animation
# -----------------------------------------------------------------------------

function plot_HOP!(
    f::Union{GridPosition,GridLayout,Figure},
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    n_boot = 20,
    rng = nothing,
    BG = :white,
    uncert_label = "SE",
    colorrange_mode = :diverging_balanced,
    axis_labelsize = 24,
    colorbar_labelsize = 24,
    colorbar_ticklabelsize = 18,
    colorbar_height = 300,
    topo_size = nothing,
)
    rng = isnothing(rng) ? Random.MersenneTwister(1) : rng
    boot_means = hcat([
        vec_estimate .+ vec_uncert .* randn(rng, length(vec_estimate))
        for _ in 1:n_boot
    ]...)

    obs = Observable(boot_means[:, 1])

    cr = _shared_scalar_topoplot_range(
        vec(boot_means);
        colorrange_mode = colorrange_mode,
    )

    topo_args =
        positions !== nothing ? (; positions=positions) :
        labels !== nothing    ? (; labels=labels) :
                                error("Either positions or labels must be provided.")

    _ = topo_size
    plot_topoplot!(
        f,
        obs;
        topo_args...,
        topo_axis = (; backgroundcolor = BG),
        visual = _scalar_topoplot_visual(;
            contours = true,
            colormap = _shared_colormap,
            colorrange = cr,
            colorrange_mode = colorrange_mode,
        ),
        colorbar = (;
            labelsize = colorbar_labelsize,
            ticklabelsize = colorbar_ticklabelsize,
            height = colorbar_height,
            ticks = _scalar_colorbar_ticks(cr; colorrange_mode = colorrange_mode),
        ),
        axis = (;
            backgroundcolor = BG,
            xlabel = uncert_label,
            xlabelsize = axis_labelsize,
            ylabelsize = axis_labelsize,
        ),
    )

    return obs, boot_means
end

function plot_HOP(
    vec_estimate,
    vec_uncert;
    positions = nothing,
    labels = nothing,
    n_boot = 20,
    rng = nothing,
    BG = :white, #BG=RGBf(0.98, 0.98, 0.98),
    uncert_label = "SE",
    colorrange_mode = :diverging_balanced,
)
    f = Figure(backgroundcolor = BG)
    obs, boot_means = plot_HOP!(
        f,
        vec_estimate,
        vec_uncert;
        positions = positions,
        labels = labels,
        n_boot = n_boot,
        rng = rng,
        BG = BG,
        uncert_label = uncert_label,
        colorrange_mode = colorrange_mode,
    )
    return f, obs, boot_means
end

# Scratch example for `plot_HOP` (expects `test` in scope).
# f, obs, boot_means = plot_HOP(test.estimate, test.se; labels = test.labels, uncert_label = "SE")

function ease_between(old, new, update_ratio; easing_function = sineio())
    anim = Animation(0, old, 1, new; defaulteasing = easing_function)
    return at(anim, update_ratio)
end

function create_HOP_gif(f, obs, boot_means; filepath = "anim.gif", framerate = 12, transition_steps = 10)
    mkpath(dirname(filepath))
    n_boot = size(boot_means, 2)
    record(f, filepath; framerate = framerate) do io
        recordframe!(io)  # first frame (original)
        for i_boot = 1:(n_boot - 1)
            new_v = boot_means[:, i_boot+1]
            old_v = copy(obs[])
            for u in range(0, 1, length = transition_steps)
                obs[] = ease_between(old_v, new_v, u)
                recordframe!(io)
            end
        end
    end
end

# Scratch example for `create_HOP_gif`.
# create_HOP_gif(f, obs, boot_means)


function get_label_pos(label)
    l = uppercase(label)
    #change value range from [-1,1] to [0,1]
    return (standard_1005_2D[l][1] / 2.0 + 0.5, standard_1005_2D[l][2] / 2.0 + 0.5)
end


function channel_to_label(channel)
    return label_in_channel_order[channel]
end

"""
    cart3d_to_spherical(x, y, z)
Convert x, y, z electrode positions on a scalp to spherical coordinate representation. 

**Return Value:** `Matrix`.
"""
function cart3d_to_spherical(x, y, z)
    sph = SphericalFromCartesian().(SVector.(x, y, z))
    sph = [vcat(s.r, s.θ, π / 2 - s.ϕ) for s in sph]
    sph = hcat(sph...)'
    return sph
end

"""
	to_positions(x, y, z; sphere = [0, 0, 0.])
	to_positions(pos::AbstractMatrix; sphere = [0, 0, 0.])
  
Projects 3D electrode positions to a 2D layout.
Reimplementation of the MNE algorithm.

Assumes `size(pos) = (3, nChannels)` when input is `AbstractMatrix`.

Tip: You can get positions directly from an MNE object after loading PyMNE and enabling the UnfoldMakie PyMNE extension.

**Return Value:** `Vector{Point2{Float64}}`. 
"""
to_positions(pos::AbstractMatrix; kwargs...) =
    to_positions(pos[1, :], pos[2, :], pos[3, :]; kwargs...)
function to_positions(x, y, z; sphere = [0, 0, 0.0])
    #cart3d_to_spherical(x,y,z)

    # translate to sphere origin
    x .-= sphere[1]
    y .-= sphere[2]
    z .-= sphere[3]

    # convert to spherical coordinates
    sph = cart3d_to_spherical(x, y, z)

    # get rid of of the radius for now
    pol_a = sph[:, 3]
    pol_b = sph[:, 2]

    # use only theta & phi, convert back to cartesian coordinates
    p_x = pol_a .* cos.(pol_b)
    p_y = pol_a .* sin.(pol_b)

    # scale by the radius
    p_x .*= sph[:, 1] ./ (π / 2)
    p_y .*= sph[:, 1] ./ (π / 2)

    # move back by the sphere coordinates
    p_x .+= sphere[1]
    p_y .+= sphere[2]
    return Point2f.(p_x, p_y)
end


const _MONTAGE_DIR = joinpath(@__DIR__, "..", "montages")

"""
    list_montages()

Lists names of built-in montages that are bundled with UnfoldMakie.

**Return Value:** `Vector{String}`.
"""
function list_montages()
    files = filter(f -> endswith(f, ".txt"), readdir(_MONTAGE_DIR))
    return replace.(files, ".txt" => "")
end

"""
    get_montage(name::AbstractString = "brainproducts-RNP-BA-128")

Reads built-in montage file and returns its electrode labels together with their positions in 2D. Montage files store spherical angles in degrees (denote with phi and theta), which
are projected into 2 dimensions using function `to_positions`. Display options with `list_montages()`.

**Return Value:** `NamedTuple` consists of `labels::Vector{String}` and `positions::Vector{Point2f}`.
"""
function get_montage(name::AbstractString = "brainproducts-RNP-BA-128")
    fname = endswith(name,".txt") ? name : name * ".txt"
    file = joinpath(_MONTAGE_DIR, fname)
    if !isfile(file)
        error("Montage \"$name\" not found. Available: $(join(list_montages(), ", "))")
    end
    labels = String[]
    thetas = Float64[]
    phis = Float64[]
    for (i, line) in enumerate(eachline(file))
        i == 1 && continue                 #file has header, skip it
        isempty(strip(line)) && continue  
        parts = split(line)
        length(parts) < 3 && continue
        push!(labels, parts[1])
        push!(thetas, parse(Float64, parts[2]))
        push!(phis, parse(Float64, parts[3]))
    end

    θ = deg2rad.(thetas)
    φ = deg2rad.(phis)
    x = sin.(θ) .* cos.(φ)
    y = sin.(θ) .* sin.(φ)
    z = cos.(θ)
    pos3d =permutedims(hcat(x, y, z))
    positions = to_positions(pos3d)

    return (; labels, positions)

end

"""
    standard_positions(labels, name::AbstractString = "brainproducts-RNP-BA-128")

Returns the 2D positions of an electrode label using built-in montage.
It will find a match regardless of the case the user inputs.
Throws an error for lack of a match.

**Return Value:** `Vector{Point2f}`.
"""
function standard_positions(
    labels::AbstractVector{<:AbstractString},
    name::AbstractString = "brainproducts-RNP-BA-128",
)
    m = get_montage(name)
    lookup = Dict(uppercase(l) => p for (l, p) in zip(m.labels,m.positions))
    positions = Point2f[]
    notfound = String[]
    for l in labels
        key = uppercase(l)
        haskey(lookup, key) ? push!(positions, lookup[key]) : push!(notfound, l)
    end
    if !isempty(notfound)
        error("Label not found in montage \"$name\": $(join(notfound, ", "))")
    end

    return positions

end
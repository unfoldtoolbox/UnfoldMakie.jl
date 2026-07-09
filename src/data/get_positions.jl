
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


const montage_dir = joinpath(@__DIR__, "..", "montages")

"""
    list_montages()

Lists names of montages UnfoldMakie features.

**Return Value:** `Vector{String}`.
"""
function list_montages()
    exts = (".txt", ".tsv", ".sfp", ".elc",".csd")
    files = filter(f -> any(e -> endswith(f, e), exts), readdir(montage_dir))
    return unique([replace(f, r"\.(txt|tsv|sfp|elc|csd)$" => "") for f in files])
end

# Normalize each electrode onto the unit sphere
# .txt/.tsv already store unit vectors
#Note that .sfp/.elc store real mm/cm
function _to_unit_sphere!(pos3d)
    for j in axes(pos3d, 2)
        n = sqrt(sum(abs2, @view pos3d[:,j]))
        n == 0 && continue
        @views pos3d[:,j] ./= n
    end
    return pos3d
end

# .txt format/header: Name Theta Phi
# spherical angles -> unit sphere
function _read_theta_phi(file)
    labels, thetas, phis = String[], Float64[], Float64[]
    for (i, line) in enumerate(eachline(file))
        i == 1 && continue
        isempty(strip(line)) && continue
        parts = split(line)
        length(parts) < 3 && continue
        push!(labels, parts[1])
        push!(thetas, parse(Float64, parts[2]))
        push!(phis, parse(Float64, parts[3]))
    end
    θ, φ = deg2rad.(thetas), deg2rad.(phis)
    x = sin.(θ) .* cos.(φ)
    y = sin.(θ) .* sin.(φ)
    z = cos.(θ)
    return labels, permutedims(hcat(x, y, z))
end

# .tsv format: label x y z
# xyz correspond to coordinates (bypasses theta/phi conversion)
function _read_xyz_tsv(file)
    labels, xs, ys, zs = String[], Float64[], Float64[], Float64[]
    for (i, line) in enumerate(eachline(file))
        i == 1 && continue
        isempty(strip(line)) && continue
        parts = split(line)
        length(parts) < 4 && continue
        push!(labels, parts[1])
        push!(xs, parse(Float64, parts[2]))
        push!(ys, parse(Float64, parts[3]))
        push!(zs, parse(Float64, parts[4]))
    end
    return labels, permutedims(hcat(xs, ys, zs))
end

# no header
# format is label x y z
function _read_sfp(file)
    labels, xs, ys, zs = String[], Float64[], Float64[], Float64[]
    for line in eachline(file)
        isempty(strip(line)) && continue
        parts = split(line)
        length(parts) < 4 && continue
        x = tryparse(Float64, parts[2])
        y = tryparse(Float64, parts[3])
        z = tryparse(Float64, parts[4])
        (x === nothing || y === nothing || z === nothing) && continue
        push!(labels, parts[1]); push!(xs, x); push!(ys, y); push!(zs, z)
    end
    return labels, _to_unit_sphere!(permutedims(hcat(xs, ys, zs)))
end

# .elc format is head block and then positions block of
# xyz lines in mm, then a Labels block of names in the same order
function _read_elc(file)
    labels, xs, ys, zs = String[], Float64[], Float64[], Float64[]
    mode = :none
    for line in eachline(file)
        s = strip(line)
        (isempty(s) || startswith(s, "#")) && continue
        if startswith(s, "Positions")
            mode = :pos; continue
        elseif startswith(s,"Labels")
            mode = :lab; continue
        elseif occursin('=', s) || startswith(s, "ReferenceLabel") ||
               startswith(s, "UnitPosition") || startswith(s, "HeadShapePoints") ||
               startswith(s, "Fiducials") || startswith(s, "Polygons") ||
               startswith(s, "NumberPolygons")
            mode = :none; continue
        end
        parts = split(s)
        if mode == :pos && length(parts) >= 3
            x = tryparse(Float64, parts[end-2])
            y = tryparse(Float64, parts[end-1])
            z = tryparse(Float64, parts[end])
            (x === nothing || y === nothing || z === nothing) && continue
            push!(xs, x); push!(ys, y); push!(zs, z)
        elseif mode == :lab && length(parts) == 1
            push!(labels, parts[1])
        end
    end
    return labels, _to_unit_sphere!(permutedims(hcat(xs, ys, zs)))
end

# .csd is only 1 montage file
#with format:
# Label Theta Phi Radius X Y Z "off sphere surface"
# function uses X Y Z
function _read_csd(file)
    labels, xs, ys, zs = String[], Float64[], Float64[], Float64[]
    for line in eachline(file)
        s = strip(line)
        (isempty(s) || startswith(s, "//")) && continue
        parts = split(s)
        length(parts) < 7 && continue
        x = tryparse(Float64, parts[5])
        y = tryparse(Float64, parts[6])
        z = tryparse(Float64, parts[7])
        (x === nothing || y === nothing || z === nothing) && continue
        push!(labels, parts[1]); push!(xs, x); push!(ys, y); push!(zs, z)
    end
    return labels, _to_unit_sphere!(permutedims(hcat(xs, ys, zs)))
end

"""
    get_montage(name::AbstractString = "brainproducts-RNP-BA-128")

Reads a built-in montage and returns its electrode labels together with their
2D positions, through `to_positions`. Five file formats are supported (everything from PyMNE):
`.txt` (spherical angles), `.tsv` (cartesian xyz, unit sphere),
`.sfp` (label + xyz in mm/cm) and `.elc` (ASA electrode file), and `.csd` (label, XYZ).
Use `list_montages()` to see specific names.

**Return Value:** `NamedTuple` consisting of `labels::Vector{String}` and `positions::Vector{Point2f}`.
"""
function get_montage(name::AbstractString = "brainproducts-RNP-BA-128")
    base = replace(name, r"\.(txt|tsv|sfp|elc|csd)$" => "")
    readers = (
        (".txt", _read_theta_phi),
        (".tsv", _read_xyz_tsv),
        (".sfp", _read_sfp),
        (".elc", _read_elc),
        (".csd", _read_csd),
    )


    for (ext, reader) in readers
        file = joinpath(montage_dir, base * ext)
        if isfile(file)
            labels, pos3d = reader(file)
            return (; labels, positions = to_positions(pos3d))
        end
    end
    error("Montage \"$name\" not found. Available montages include: $(join(list_montages(), ", "))")
end

"""
    standard_positions(labels, name::AbstractString = "brainproducts-RNP-BA-128")

Returns the 2D positions of the given electrode labels using built-in montage.
Matching is case insensitive. Throws error listing any labels not found.

**Return Value:** `Vector{Point2f}`.
"""
function standard_positions(
    labels::AbstractVector{<:AbstractString},
    name::AbstractString = "brainproducts-RNP-BA-128",
)
    m = get_montage(name)
    lookup = Dict(uppercase(l) => p for (l, p) in zip(m.labels, m.positions))
    positions = Point2f[]
    notfound = String[]

    for l in labels
        key = uppercase(l)
        haskey(lookup, key) ? push!(positions, lookup[key]) : push!(notfound, l)
    end

    isempty(notfound) ||
        error("Label is not found in montage \"$name\": $(join(notfound, ", "))")
    return positions
end
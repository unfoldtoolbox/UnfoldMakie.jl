
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

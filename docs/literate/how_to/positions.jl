# #  Convert electrode positions from 3D to 2D
# Sometimes you have 3D montage but you need 2D montage. How to convert one to another? The function `to_positions` should help.

using UnfoldMakie
using CairoMakie

# # Generate example 3D positions

# Generate deterministic electrode-like positions on a sphere.

azimuths = range(0, 2π; length = 17)[1:end-1]
inclinations = range(π / 8, 3π / 8; length = 4)

pos3d = hcat([
    [
        sin(inclination) * cos(azimuth),
        sin(inclination) * sin(azimuth),
        cos(inclination),
    ] for inclination in inclinations for azimuth in azimuths
]...)

# # Projecting from 3D montage to 2D
pos2d = to_positions(pos3d)

begin
    f = Makie.Figure(size = (600, 300))
    Makie.scatter(f[1, 1], pos3d[1:2, :], axis = (title = "Dropping third dimension",))
    Makie.scatter(f[1, 2], pos2d, axis = (title = "Projection from 3D to 2D",))
    f
end
# As you can see, the "naive" transformation of simply dropping the third dimension does not really work (left). Instead, we have to project the channels onto a sphere and unfold it (right).


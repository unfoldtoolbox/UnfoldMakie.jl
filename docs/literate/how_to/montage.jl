using PyMNE

# There are dozens of standard and arbitrary ways to set electrodes. 
# Using PyMNE package you can get 27 predefined montages with corresponding lavels and channel positions. 
builtin_montages = PyMNE.channels.get_builtin_montages(descriptions = true)

for (name, desc) in builtin_montages
    println("$(name): $(desc)")
end

begin
    f = Figure(size = (800, 500))
    for (i, (title, montage)) in enumerate(
        [("Biosemi", biosemi_montage), ("10-20", montage_1020), ("10-05", standard_1005), ("brainproducts-128", brainproducts-RNP-BA-128)], 
    )
        labels = pyconvert(Vector{String}, montage.ch_names)
        ch_pos = pyconvert(Dict{String,Any}, montage.get_positions()["ch_pos"])
        pos3d = hcat([ch_pos[l] for l in labels]...)
        pos2 = to_positions(pos3d)

        scatter(f[1, i], pos2, axis = (title = title,))
        text!(f[1, i], labels, position = Point2f.(pos2),
            align = (:center, :center), fontsize = 16)
    end
    f
end

begin
    f = Figure(size = (1200, 500))

    montages = [
        ("Biosemi", "biosemi64"),
        ("10-20", "standard_1020"),
        ("10-05", "standard_1005"),
        ("brainproducts-128", "brainproducts-RNP-BA-128"),
    ]

    for (i, (title, mname)) in enumerate(montages)
        montage = PyMNE.channels.make_standard_montage(mname)

        labels = pyconvert(Vector{String}, montage.ch_names)
        ch_pos = pyconvert(Dict{String,Any}, montage.get_positions()["ch_pos"])
        pos3d = hcat([ch_pos[l] for l in labels]...)
        pos2 = to_positions(pos3d)

        scatter(f[1, i], pos2, axis = (title = title,))
        text!(f[1, i], labels, position = Point2f.(pos2),
            align = (:center, :center), fontsize = 16)
    end

    f
end

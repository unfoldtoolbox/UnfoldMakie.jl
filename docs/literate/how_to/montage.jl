using PyMNE

# There are dozens of standard and arbitrary ways to set electrodes. 
# Using PyMNE package you can get 27 predefined montages with corresponding lavels and channel positions. 
builtin_montages = PyMNE.channels.get_builtin_montages(descriptions = true)

for (name, desc) in builtin_montages
    println("$(name): $(desc)")
end


begin
    f = Figure(size = (1200, 800))

    montages = [
        ("Biosemi", "biosemi64"),
        ("10-20", "standard_1020"),
        ("10-05", "standard_1005"),
        ("brainproducts-128", "brainproducts-RNP-BA-128"),
    ]

    for (i, (title, mname)) in enumerate(montages)
        row = (i - 1) ÷ 2 + 1
        col = (i - 1) % 2 + 1
        montage = PyMNE.channels.make_standard_montage(mname)

        labels = pyconvert(Vector{String}, montage.ch_names)
        ch_pos = pyconvert(Dict{String,Any}, montage.get_positions()["ch_pos"])
        pos3d = hcat([ch_pos[l] for l in labels]...)
        pos2 = to_positions(pos3d)

        scatter(f[row, col], pos2, axis = (title = title,))
        text!(
            f[row, col],
            labels,
            position = Point2f.(pos2),
            align = (:center, :center),
            fontsize = 16,
        )
    end

    f
end

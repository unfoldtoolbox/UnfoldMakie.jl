hart = Hartmut()
idx_64 = findall(l -> l in UnfoldMakie._labels_64, hart.electrodes["label"])
hart_estimate = hart.cortical["leadfield"][idx_64, 312, :] * [0.2, 0.4, 0.4]
positions_hart = begin
    pos2 = to_positions(hart.electrodes["pos"]')
    pos2 = [UnfoldMakie.Point2f(p[1] + 0.5, p[2] + 0.5) for p in pos2]
    pos2[idx_64]
end
labels_hart = hart.electrodes["label"][idx_64]

plot_topoplot(
    hart_estimate;
    labels = labels_hart,
    positions = positions_hart,
    visual = (; label_text = true, label_scatter = false),
    axis = (; xlabel = ""),
)

hart_label_data = Dict(labels_hart .=> hart_estimate)


begin
    montage = PyMNE.channels.make_standard_montage("biosemi64")
    hart_label_data
    ch_pos = pyconvert(Dict{String,Any}, montage.get_positions()["ch_pos"])

end

hart_label_data = Dict(labels_hart .=> hart_estimate)  # or any data vector
ch_pos = pyconvert(Dict{String,Any}, montage.get_positions()["ch_pos"])
pos3d = hcat([ch_pos[l] for l in labels]...)
pos2 = to_positions(pos3d)

data_ordered = [hart_label_data[l] for l in labels]
pos3d = hcat([ch_pos[l] for l in labels]...)


plot_topoplot(
    hart_estimate;
    labels = labels_64,
    positions = positions_64,
    visual = (; label_text = true, label_scatter = false),
    axis = (; xlabel = ""),
)


begin
    f = Figure(size = (1200, 800))
    for (i, mname) in enumerate([
        "biosemi64",
        "standard_1020",
        "standard_1005",
        "brainproducts-RNP-BA-128",
    ],)
        row = (i - 1) ÷ 2 + 1
        col = (i - 1) % 2 + 1
        montage = PyMNE.channels.make_standard_montage(mname)

        labels = pyconvert(Vector{String}, montage.ch_names)
        ch_pos = pyconvert(Dict{String,Any}, montage.get_positions()["ch_pos"])
        pos3d = hcat([ch_pos[l] for l in labels]...)
        pos2 = to_positions(pos3d)

        scatter(f[row, col], pos2, axis = (title = mname,))
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

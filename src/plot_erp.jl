function plot_erp(data::Matrix{Float64},config::PlotConfig)

    ix = sortperm([a[1] for a in argmax(data, dims=1)][1,:])   # ix - trials sorted by time of maximum spike
    sort_x = [[a[1] for a in argmax(data,dims=2)]...]
    # @show ix
    # @show sort_x
    f = Figure()
    ax = Axis(f[1:4,1])
    # sortperm() computes a permutation of the array's indices that puts the array into sorted order:
    hm = heatmap!(ax,(data[:,ix]); config.visualData...)
    show(hm)
    # image(f[1:4,1],data[:,ix]; config.visualData...)
    # ax = current_axis()
    ax.xlabel = config.extraData.xlabel
    ax.ylabel = config.extraData.ylabel

    # Colorbar(f[:, 2],hm; config.colorbarData..., config.visualData.colormap)
    Colorbar(f[:, 2], hm; config.colorbarData...) 

    hidespines!(ax, :t, :r) 

    lines(f[5,1],mean(data,dims=2)[:,1])

    return f

end
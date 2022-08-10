function plot_erp(data::Matrix{Float64},config::PlotConfig)
    # ix = [[a[1] for a in data]...]

    f = Figure()
    ax = Axis(f[1:4,1])

    if config.extraData.sortData
        ix = sortperm([a[1] for a in argmax(data, dims=1)][1,:])   # ix - trials sorted by time of maximum spike
        # sort_x = [[a[1] for a in argmax(data,dims=2)]...]
        hm = heatmap!(ax,(data[:,ix]); config.visualData...)
    else
        hm = heatmap!(ax,(data[:,:]); config.visualData...)
    end
    # @show ix
    # @show sort_x
   
    # sortperm() computes a permutation of the array's indices that puts the array into sorted order:
    
    # show(hm)
    # image(f[1:4,1],data[:,ix]; config.visualData...)
    # ax = current_axis()
    ax.xlabel = config.extraData.xlabel
    ax.ylabel = config.extraData.ylabel

    # Colorbar(f[:, 2],hm; config.colorbarData..., config.visualData.colormap)
    Colorbar(f[:, 2], hm; config.colorbarData...) 

    hidespines!(ax, :t, :r) 
    if config.extraData.meanPlot
        lines(f[5,1],mean(data,dims=2)[:,1])
    end

    return f

end
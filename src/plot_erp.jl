using ImageFiltering


function plot_erp(data::Matrix{Float64},config::PlotConfig)
    # ix = [[a[1] for a in data]...]

    f = Figure()
    ax = Axis(f[1:4,1])

    # make sure blur is never negative
    @show config.extraData.erpBlur
    # config.extraData.erpBlur = config.extraData.erpBlur < 0 ? 0 : config.extraData.erpBlur 
    filtered_data = imfilter(data, Kernel.gaussian((0,config.extraData.erpBlur)))
    
    if config.extraData.sortData
        ix = sortperm([a[1] for a in argmax(data, dims=1)][1,:])   # ix - trials sorted by time of maximum spike
        hm = heatmap!(ax,(filtered_data[:,ix]); config.visualData...)
    else
        hm = heatmap!(ax,(filtered_data[:,:]); config.visualData...)
    end
    # @show ix
    # @show sort_x

    # sortperm() computes a permutation of the array's indices that puts the array into sorted order:
    
    # show(hm)
    # image(f[1:4,1],data[:,ix]; config.visualData...)
    # ax = current_axis()
    ax.xlabel = config.extraData.xlabel === nothing ? string(config.mappingData.x) : config.extraData.xlabel
    ax.ylabel = config.extraData.ylabel === nothing ? string(config.mappingData.y) : config.extraData.ylabel

    if config.extraData.ylims !== nothing
        ylims!(config.extraData.ylims...)
        # xlims!(0,0.8)
    end

    Colorbar(f[:, 2], hm; config.colorbarData...)

    hidespines!(ax, :t, :r)
    if config.extraData.meanPlot
        # UserInput
        lines(f[5,1],mean(data,dims=2)[:,1])
        ax2 = current_axis()
        ax2.xlabel = config.extraData.xlabel === nothing ? string(config.mappingData.x) : config.extraData.xlabel
        ax2.ylabel = config.colorbarData.label === nothing ? "" : config.colorbarData.label
        hidespines!(ax2, :t, :r)
    end

    return f

end
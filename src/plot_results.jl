using AlgebraOfGraphics
using Makie
using DataFrames
using ..PlotConfigs

function plot_lineTest(results::DataFrame, config::PlotConfig;y=nothing,
    pvalue = DataFrame(:from=>[],:to=>[]))
    
    results = deepcopy(results)
    @show names(results)
    @show config.data

    f = Figure()
    
    if isnothing(y)
        y = "estimate" ∈  names(results) ? :estimate : "yhat" ∈  names(results) ? :yhat : @error("please specify y-axis")
    end
    if "group" ∈  names(results)
        results.group = results.group .|> a -> isnothing(a) ? :fixef : a
    end

    plotEquation = visual(Lines) * data(results) * mapping(config.data.x, config.data.y;config.getCollumns(results)...)
    mainPlot = draw!(f[1, 1], plotEquation)

    #legend!(f[1, 1], f[2, 1], "Channels", orientation = :horizontal, tellwidth = false, tellheight = true, nbanks=2)

    #labels = unique(results[:,:coefname])

    #groups = labels .|> coefname -> filter(:coefname => n -> n == coefname, results)

    #colors = [:red, :green, :blue, :orange]

    #collect(zip(groups, labels, colors)) .|> d -> lines!(d[1].time, d[1].estimate, label=d[2], color=d[3])

    # Legend inside
    # axislegend(position = :rb)
    # Legend beneath
    # Legend(f[2, 1], ax, "Channels", orientation = :horizontal, tellwidth = false, tellheight = true, nbanks=2)
    # Legend next to
    # Legend(f[1, 2], ax, "Channels", orientation = :vertical, tellwidth = true, tellheight = false)

    # USEFULL SNIPPET
    # data( @subset(results_all,:basisname .== "other")) * mapping(:time,:estimate,color=:subject=>nonnumeric,layout=:coefname=>nonnumeric)*visual(Lines)|>draw
    #plt->draw(plt, legend=(position=:top,)=>nonnumeric)

    if(config.data.showLegend)
        legend!(f[2, 1], mainPlot; config.data...)
    end

    return f #draw(mainPlot, legend=config.data)
end


function plot_results(results::DataFrame;y=nothing,
    color=:coefname,
    col=:basisname,
    row=:group,
    stderror=false,
    pvalue = DataFrame(:from=>[],:to=>[]),
    kwargs...)

    results = deepcopy(results)

    @assert "time" ∈ names(results) ":time has to be a column of the input dataframe"

    if isnothing(y)
        y = "estimate" ∈  names(results) ? :estimate : "yhat" ∈  names(results) ? :yhat : @error("please specify y-axis")
    end

    # replace missing/nothing values
    if "group" ∈  names(results)
        results.group = results.group .|> a -> isnothing(a) ? :fixef : a
    end
    if "stderror" ∈  names(results) && stderror
        results.stderror = results.stderror .|> a -> isnothing(a) ? 0. : a
        results[!,:se_low]  = results[:,y] .- results.stderror
        results[!,:se_high] = results[:,y] .+ results.stderror
    end
    
    # check if mappings exist
    
    if string(color) ∉ names(results)
        color != :coefname ? @error("user specified color=$color not found in DataFrame") : nothing
        color = 1
    end
    if string(col) ∉ names(results)
        col != :basisname ? @error("user specified col=$col not found in DataFrame") : nothing
        col = 1
    end
    if string(row) ∉ names(results)
        row != :group ? error("user specified row=$row not found in DataFrame") : nothing
        row = 1
    end

    m = mapping(color=color,col=col,row=row;kwargs...)

    m_li = mapping(:time,y)

    basic =  visual(Lines) * m_li
    
    if stderror
        m_se = mapping(:time,:se_low,:se_high)
        basic = basic + visual(Band,alpha=0.5)*m_se
    end

    basic = basic*data(results)
       
    
    

    # add the pvalues
    if !isempty(pvalue)
        p = deepcopy(pvalue)

        # for now, add them to the fixed effect
        if "group" ∉  names(p)
            # group not specified using first
            if "group" ∈  names(results)
                p[!,:group] .= results[1,:group]
                if length(unique(results.group))>1
                    @warn "multiple groups found, choosing first one"
                end
            else
                p[!,:group] .= 1
            end
        end
        

        # rename to match the res-dataframe

        shouldHave = hcat(col,row,color)
        shouldHave = shouldHave[shouldHave.!=1] # remove defaults as defined above
        if ~isempty(kwargs)
             shouldHave = hcat(shouldHave,(values(kwargs)))
        end
        shouldHave = string.(shouldHave)
        
        for k in shouldHave
            if k ∉ names(p)
                p[!,k] .= results[1,k]
            end

        end

        @show color
        @show p
        un = unique(p[!,color])
        # define an index to dodge the lines vertically
        p[!,:sigindex] .=  [findfirst(un .== x) for x in p.coefname]

        scaleY = [minimum(results.estimate),maximum(results.estimate)]
        stepY = scaleY[2]-scaleY[1]
        posY = stepY*-0.05+scaleY[1]
        Δt = diff(results.time[1:2])[1]
        Δy = 0.01
        p[!,:segments] = [Makie.Rect(Makie.Vec(x,posY+stepY*(Δy*(n-1))),Makie.Vec(y-x+Δt,0.5*Δy*stepY)) for (x,y,n) in zip(p.from,p.to,p.sigindex)]

        basic =  basic + (data(p)*mapping(:segments)*visual(Poly))
    end

    # draw it!

    d = basic*m|> draw
    return d
    
end



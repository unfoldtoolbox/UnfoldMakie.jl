using AlgebraOfGraphics
using Makie
using DataFrames

function plot_results(results::DataFrame;y=nothing,
    color=:coefname,
    col=:basisname,
    row=:group,
    stderror=false,
    pvalue = DataFrame(:from=>[],:to=>[],:pval=>[]),kwargs...)

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
        color != :coefname ? @warn("user specified color=$color not found in DataFrame, ignoring it") : nothing
        color = 1
    end
    if string(col) ∉ names(results)
        col != :basisname ? @warn("user specified col=$col not found in DataFrame, ignoring it") : nothing
        col = 1
    end
    if string(row) ∉ names(results)
        row != :group ? @warn("user specified row=$row not found in DataFrame, ignoring it") : nothing
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
        p[!,layout] .= :fixef

        # rename to match the res-dataframe
        p[!,:coefname] = p.coefname
 
        un = unique(p.coefname)
        scaleY = [minimum(results.estimate),maximum(results.estimate)]
        stepY = scaleY[2]-scaleY[1]
        posY = stepY*-0.05+scaleY[1]
        Δt = diff(results.colname_basis[1:2])[1]
        Δy = 0.01
        p[!,:color] .=  [findfirst(un .== x) for x in p.coefname]
        p[!,:segments] = [Rect(Vec(x,posY+stepY*(Δy*(n-1))),Vec(y-x+Δt,0.5*Δy*stepY)) for (x,y,n) in zip(p.from,p.to,p.color)]

        basic =  basic + (data(p)*mapping(:segments)*visual(Poly))
    end

    # draw it!

    d = basic*m|> draw
    return d
    
end



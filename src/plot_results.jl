using AlgebraOfGraphics
using Makie
using DataFrames

#---
#Plots.plot(m::Unfold.UnfoldModel)  = plot_results(m.results)


plot(m::Unfold.UnfoldModel) = plot_results(Unfold.condense_long)
function plot_results(results::DataFrame;y=:estimate,color=:coefname,col=:basisname,row=:group,stderror=false,pvalue = DataFrame(:from=>[],:to=>[],:pval=>[]))
    results = deepcopy(results)

    # replace missing/nothing valuess
    results.group = results.group .|> a -> isnothing(a) ? :fixef : a
    results.stderror = results.stderror .|> a -> isnothing(a) ? 0. : a
    

    results[!,:se_low]  = results[:,y] .- results.stderror
    results[!,:se_high] = results[:,y] .+ results.stderror
    

    m = mapping(color=color,col=col,row=row)

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

        # probably not needed
        #p[!,:colname_basis] .= results.colname_basis[1]
        
        # 
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
    d = basic*m|> draw
    return d
    
end


#using SparseArrays
#Plots.heatmap(X::SparseMatrixCSC) = heatmap(Matrix(X))

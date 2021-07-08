
using Makie
import Makie.plot
using StatsBase
function plot(X::Unfold.DesignMatrix;standardize=true,sort=false)

    designmat = X.Xs[1]';
    if standardize
        designmat = designmat ./ std(designmat,dims=2)
        designmat[isinf.(designmat)] .= 1.
    end
    if sort
        designmat = sort(designmat,dims=2)
    end
    labels = coefnames(X.formulas.rhs)[1:size(designmat,1)]

    # plot Designmatrix
    fig, ax, hm = heatmap(designmat,axis=(xticks=(1:8,labels),xticklabelrotation = pi/8),)
    Colorbar(fig[1,2],hm)
    

end

function plot2(X::Unfold.DesignMatrix;standardize=true,sort=false)

    # plot events on top
    hline!()
end
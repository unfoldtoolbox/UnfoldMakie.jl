module UnfoldMakieUnfoldExt

using Unfold
using UnfoldMakie
using GridLayoutBase
using Makie
# Unfold Backward Compatability. AbstractDesignMatrix was introduced only in v0.7
if isdefined(Unfold, :AbstractDesignMatrix)
    # nothing to do for AbstractDesignMatrix, already imprted
    # backward compatible accessor
    #const drop_missing_epochs = Unfold.drop_missing_epochs
    #const modelmatrices = Unfold.modelmatrices
else
    const AbstractDesignMatrix = Unfold.DesignMatrix
    #const drop_missing_epochs = Unfold.dropMissingEpochs
    #const modelmatrices = Unfold.get_Xs
end

import UnfoldMakie.supportive_defaults
import UnfoldMakie._docstring
include("plot_splines.jl")
include("plot_designmatrix.jl")




end


using Makie
import Makie.plot
using Statistics
using SparseArrays

module PlotConfigs

function filterTup(tuple)
    list = collect(values(tuple))
    return tuple[keys(tuple)[.!isnothing.(list)]]
end

"""
This struct contains all the configurations of a plot
"""
mutable struct PlotConfig
    data::NamedTuple
    setAnyValues::Function
    setLegendValues::Function
    filterCollumns::Function

    "plot types: :lineplot, :designmatrix, :topolot"
    function PlotConfig(pltType)
        this = new()
        
        # standard values for ALL plots
        this.data = (
            color=:blue
            ,notatype=:none
        )

        # standard values for each plotType
        if (pltType == :lineplot)
            this.data = merge(this.data, (;
                notatype=:lineplot,
                color=:coefname
            ))
        elseif (pltType == :designmatrix)
            this.data = merge(this.data, (;
                type=:designmatrix
            ))
        elseif (pltType == :topolot)
            this.data = merge(this.data, (;
                type=:topolot
            ))
        end

        # setter for Any values for experimental users
        this.setAnyValues = function (;kwargs...)
            this.data = merge(this.data, kwargs)
            return this
        end

        # setter for SOME values for safe users
        this.setLegendValues = function (;color=nothing, align=nothing)
            tuple = (color=color, align=align)
            tuple = filterTup(tuple)
            this.data = merge(this.data, tuple)
            return this
        end

        this.filterCollumns = function (data)
            list = collect(values(this.data))
            function isCollumn(value) string(value) ∈ names(data) end
            return this.data[keys(this.data)[isCollumn.(list)]]
        end

        return this
    end
end

export PlotConfig

end
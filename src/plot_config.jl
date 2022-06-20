
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
    extraData::NamedTuple
    visualData::NamedTuple
    mappingData::NamedTuple
    legendData::NamedTuple
    
    
    setExtraValues::Function
    setVisualValues::Function
    setMappingValues::Function
    setLegendValues::Function

    resolveMappings::Function

    "plot types: :lineplot, :designmatrix, :topolot"
    function PlotConfig(pltType)
        this = new()

        # standard values for ALL plots
        this.extraData = (
            
            showLegend=true,
        )

        this.visualData = NamedTuple()

        this.mappingData = (
            x=:time,
            y=:estimate,
        )
        
        this.legendData = NamedTuple()
        
        # setter for ANY values for Data
        this.setExtraValues = function (;kwargs...)
            this.extraData = merge(this.extraData, kwargs)
            return this
        end
        this.setVisualValues = function (;kwargs...)
            this.visualData = merge(this.visualData, kwargs)
            return this
        end
        this.setMappingValues = function (;kwargs...)
            this.mappingData = merge(this.mappingData, kwargs)
            return this
        end
        this.setLegendValues = function (;kwargs...)
            this.legendData = merge(this.legendData, kwargs)
            return this
        end
            
        # standard values for each plotType
        if (pltType == :lineplot)
            this.setExtraValues(
                type=:lineplot,
            )
            this.setMappingValues(
                col=:basisname,
                row=:group,
                color=:coefname
            )
        elseif (pltType == :designmatrix)
            this.setVisualValues(
                axis=(
                    xticklabelrotation=pi/8,
                ),
            )
        elseif (pltType == :topolot)

        end


        this.resolveMappings = function (plotData)
            function isCollumn(col)
                string(col) ∈ names(plotData)
            end
            function getAvailable(choices)
                choices[keys(choices)[isCollumn.(collect(choices))]]
            end
            return map(val -> isa(val, Tuple) ? getAvailable(val)[1] : val, this.mappingData)
        end



        return this
    end
end

export PlotConfig

end
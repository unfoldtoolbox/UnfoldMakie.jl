## [General Topo Plot Visualization](@id tp_vis)

### Include used modules
The following modules are necessary:
```@example main
using Unfold
using UnfoldMakie
using StatsModels # can be removed in Unfold v0.3.5
using DataFrames
using CairoMakie
using TopoPlots
```
To visualize topo plots we use the `TopoPlots` module.

### Data
In case you do not already have data, you can get example data from the `TopoPlots` module. 
You can do it like this:
```@example main
f = Figure()
	
data, positions = TopoPlots.example_data()
# show(data)
labels = ["s$i" for i in 1:size(data, 1)]
# data[:, 340, 1]
f, ax, h = eeg_topoplot(data[:, 340, 1], labels; label_text=false,positions=positions, axis=axisSettings)
# show(ax.bbox)
axis = Axis(f, bbox = BBox(100, 0, 0, 100); axisSettings...)


draw = eeg_topoplot!(axis, zeros(64), labels; label_text=falsepositions=positions)
	
f
data
```

In this example we handle colors using the `Colors` and `ColorSchemes` module.
```@example main
using Colors
using ColorSchemes
```

### Configurations for ERP Images
```@example main
axisSettings = (topspinevisible=false,rightspinevisible=false,bottomspinevisible=false,leftspinevisible=false,xgridvisible=false,ygridvisible=false,xticklabelsvisible=false,yticklabelsvisible=false, xticksvisible=false, yticksvisible=false)
```

```@example main
struct NullInterpolator <: TopoPlots.Interpolator
        
end
    
function (ni::NullInterpolator)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})
    
      
    return zeros(length(xrange),length(yrange))
end

# colorscheme where first entry is 0, and exactly length(positions)+1 entries
specialColors = ColorScheme(vcat(RGB(1,1,1.),[RGB{Float64}(i, i, i) for i in range(0,1,length(positions))]...))

    
eeg_topoplot(1:length(positions), # go from 1:npos
    string.(1:length(positions)); 
positions=positions,
interpolation=NullInterpolator(), # inteprolator that returns only 0
colorrange = (0,length(positions)), # add the 0 for the white-first color
colormap= specialColors)
```

## TODO: MORE CONFIG DETAILS ONCE FINISHED
- check whether order works
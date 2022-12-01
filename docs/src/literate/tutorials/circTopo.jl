## Circular Topoplot Arrangement


using UnfoldMakie
using CairoMakie
using TopoPlots # for example data
using Random
using DataFrames

data,pos = TopoPlots.example_data();

dat = data[:, 240, 1]

# Generate a Dataframe. We need to specify the TopoPlot Positions either via position, or via labels (according to TopoPlots.jl)
df= (DataFrame(
    :estimate=>Float64.([dat;dat;dat;dat;dat;dat]),
    :circularVariable=>repeat([0,50,80,120,180,210],inner=length(dat)),
    :positions=>repeat(pos,6)));
    
df.estimate .= df.estimate .+ rand(length(df.estimate)) # add some noise
# generate the plot
f = Figure()
plot_circulareegtopoplot!(f[1,1],df;setAxisValues=(;label="Sac Incoming"),predictor=:circularVariable);
f

# In case the bounding variable is not between 0 and 360, we have to specify it. e.g.
df.circularVariable = df.circularVariable./360
plot_circulareegtopoplot!(f[1,2],df;setAxisValues=(;label="Sac Incoming"),predictor=:circularVariable,setExtraValues=(;predictorBounds=[0,1]))

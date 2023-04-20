# [Include multiple Visualizations in one Figure](@id ht_mvf)

```@example main
using UnfoldMakie
using CairoMakie
using DataFramesMeta
using UnfoldSim
```


In this section we discuss how users are able to include multiple visualizations in a single figure.

By using the !-version of the plotting function and putting in a grid position instead of a full figure, we can create Multiple Coordinated Views.

You start by creating a figure with Makie.Figure. 

`f = Figure()`

Now each plot can be added to `f`  by putting in a grid position, such as `f[1,1]`.

```@example main
f = Figure()
plot_erp!(f[1,1],results)
plot_butterfly!(f[2,1],results_plot_butter;positions=positions)

f
```


By using the data from the tutorials we can create a big image with every type of plot.

With so many plots at once it's incentivised to set a fixed resolution in your figure to order the plots evenly (Code below).


```@example main
f = Figure(resolution = (2000, 2000))

    plot_butterfly!(f[1, 1], results_plot_butter)
    
plot_erp!(f[1,2],results,extra=(;
        categoricalColor=false,
        categoricalGroup=false,
        stderror=true))




    pvals = DataFrame(
            from=[0.1,0.15],
            to=[0.2,0.5],
            # if coefname not specified, line should be black
            coefname=["(Intercept)","category: face"]
        )
plot_erp!(f[1,3],results,extra=(;pvalue=pvals))
    


data,evts = UnfoldSim.predef_eeg(;return_epoched=true)
form  = @formula 0~1+condition+continuous

# generate ModelStruct
ufMass = UnfoldLinearModel(Dict(Any=>(form,1:size(data,1)))) 
# generate designmatrix
designmatrix!(ufMass, evts)


    
    plot_designmatrix!(f[2,1], designmatrix(ufMass))

    plot_designmatrix!(f[2,2], designmatrix(ufMass);visual=(;colormap=:inferno))

    topodata, positions = TopoPlots.example_data()
    plot_topoplot!(f[3,1], topodata[1:4, 340, 1];
        labels=["O1", "F2", "F3", "P4"])
    df = DataFrame()
    df.estimate = topodata[1:4, 340, 1]
    df.labels = ["O1", "F2", "F3", "P4"]
    
    
    plot_topoplot!(f[3,2], df;positions=positions[1:4],visual=(;colormap=:viridis))

   
plot_parallelcoordinates!(f[3,3], results_plot_butter,[5,3,2];mapping=(;color=:coefname))    


f
```


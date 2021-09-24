	using Dierckx
	using ColorSchemes
	using GeometryTypes
	using Statistics
	using TimerOutputs
	
    function topoplot(data;positions=defaultLocations(),fig=Figure(),levels=5,labels=nothing,s=10^6)
        to =TimerOutput()
        
        diameter = 1
        @timeit to "posMap" X,Y = position_to_2d(positions)
        @timeit to "grid" xg,yg,v = generate_topoplot_grid(X,Y,data;s=s)
        
        # remove everything in a circle (should be ellipse at some point)
        ix = sqrt.([i.^2+j.^2 for i in yg, j in xg]).> (diameter./2)
        v[ix] .= NaN
        
    
        @timeit to "axis" ax = fig[1,1] = Axis(fig, aspect=AxisAspect(1), title="")
        cmap = ColorSchemes.vik;
        @timeit to "heatmap" heatmap!(ax,yg,xg,v,colormap=cmap)
        @timeit to "contour" contour!(ax,yg,xg,Float64.(v),linewidth=3,colormap=cmap,levels=levels)
        @timeit to "scatter" draw_electrodes(ax,X,Y)
        @timeit to "earNose" draw_earNose(ax,diameter=diameter)
        
        @timeit to "labels" draw_labels(ax,X,Y,labels)
        
        @timeit to "hidedecorations" hidedecorations!(ax)
        @timeit to "hidespines"  hidespines!(ax)
    
        fig,to
    end

    function draw_electrodes(ax,X,Y)
        scatter!(ax,X,Y,markersize=3,color="white",strokewidth=3,strokecolor="black") # add electrodes
   end

   function draw_labels(ax,X,Y,::Nothing)
    # in case of empty labels
   end
   function draw_labels(ax,X,Y,labels)
	#text!(ax, [("$(l)", Point2f0(Y[i],X[i])) for (i,l) in enumerate(labels)]) # add labels
	pos = [(x,y) for (x,y) in zip(X,Y)]
	

	text!(ax,labels,position=pos,align=(:center,:center))
	
end

function position_to_2d(positions::Matrix{T}) where {T<:Number}
    # mne layout positions
    return positions[:,1] .- 0.5,positions[:,2] .- 0.5
end

# default positions (maybe remove in future?)
function position_to_2d(positions::Vector{Tuple})
    # We could try some spherical mapping tool?
    X = first.(first.(positions)) 
    Y = last.(first.(positions))
    return X,Y
end

function generate_topoplot_grid(X,Y,data;s =10^6 )

	# get extrema and extend
	by = 0.4
	xlim = extrema(X) .+ abs.(extrema(X)).*[-by, by]
	ylim = extrema(Y).+ abs.(extrema(Y)).*[-by, by]


	# generate and evaluate a grid
	xg = range(xlim[1],stop=xlim[2],  step=0.005)
	yg = range(ylim[1],stop=ylim[2], step=0.005)
	
	# s = smoothing parameter, kx/ky = spline order; for some reason s has to be increadible large...
	spl = Spline2D(X, Y,data,kx=3,ky=3,s=s) 
			v = evalgrid(spl,yg,xg) # evaluate the spline at the grid locs
	
	
	# Would love to use Interpolations.jl, but their 2dsplines only work on a regular grid (as of v0.9)
			#interp_cubic = LinearInterpolation((X, Y), data)
			#v=interp_cubic.(xg, yg)
	
			return xg,yg,v
end

function draw_earNose(ax;diameter = 0.2)

	# draw circle
	cx,cy = circleFun(center=(.0, .0), diameter=diameter, npoints = 100) # center on [.5, .5]
	lines!(ax,cx,cy,linewidth=3,color=:black)
	# draw nose
	nx = [-0.05, 0., .05].*diameter
	ny = [.5, .55, .5].*diameter
	lines!(ax,nx,ny,linewidth=3,color=:black)


			ear_x = [.497, .510, .518, .5299, .5419, .54, .547,.532, .510, .489].*diameter
			ear_y = [.0555, .0775, .0783, .0746, .0555, -.0055, -.0932, -.1313, -.1384, -.1199].*diameter
			lines!(ax,ear_x,ear_y,linewidth=3,color=:black) # right
			lines!(ax,-ear_x,ear_y,linewidth=3,color=:black) # left
end


function circleFun(;center = (0,0),diameter = 1, npoints = 100)
    r = diameter / 2
    tt = range(0,stop=2*π,length = npoints)
    xx = center[1] .+ r * cos.(tt)
    yy = center[2] .+ r * sin.(tt)
    return (xx, yy)
  end

  
function defaultLocations()

    defaultlocs = """
    1	-18	0.34074074	FP1.
    2	18	0.34074074	FP2.
    3	-39	0.22222222	F3..
    4	39	0.22222222	F4..
    5	-90	0.17037037	C3..
    6	90	0.17037037	C4..
    7	-141	0.22222222	P3..D
    8	141	0.22222222	P4..
    9	-162	0.34074074	O1..
    10	162	0.34074074	O2..
    11	-54	0.34074074	F7..
    12	54	0.34074074	F8..
    13	-90	0.34074074	T3..
    14	90	0.34074074	T4..
    15	-126	0.34074074	T5..
    16	126	0.34074074	T6..
    17	0	0.17037037	FZ..
    18	180	0.17037037	PZ..
    19	-108	0.34074074	T5'.
    20	108	0.34074074	T6'.
    21	-144	0.34074074	O1'.
    22	144	0.34074074	O2'.
    23	-151	0.27407407	P3".
    24	151	0.27407407	P4".
    25	180	0.25555556	PZ".
    26	180	0.34074074	OZ..
    27	180	0.42592593	I...
    28	-162	0.42592593	CB1"
    29	162	0.42592593	CB2"
    30	-144	0.42592593	CB1.
    31	144	0.42592593	CB2.
    """
    
    positions = map(split(defaultlocs, "\n", keepempty=false)) do line
        pos = split(line, "\t")
        t, r = parse.(Float64, pos[2:3])
        t = deg2rad(t)
        p = Point2f0(r * cos(t), r * sin(t))
        n = replace(pos[2], "."=>"")
        return (p, n)
    end
    return positions

end
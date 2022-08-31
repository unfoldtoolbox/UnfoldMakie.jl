## [Fix Parallel Coordinates Plot](@id ht_fpcp)

Since Makie didn't have a native function to draw PCPs our version is somewhat experimental for broad applications.

Under certain circumstances the PCP is not properly visualized.
This leads to cut of edges of the PCP, and unused space.

Especially when changing the container size by customizing the figure resolution, or adding multiple plots into one figure, the PCP can have problems fitting inside.

![Default Timeexpanded Designmatrix](../images/broken_PCP.png)

Since the plot could have more space above and below, we can change the aspect ratio of the plot with:
`

`

The labels cut off at the top can be restored with
`

`

, the plot collides with the lower numbers, the numbers on the left are cut off

To mitigate the effects you can use multiple variables to manually shift the border around the plot.



```



```



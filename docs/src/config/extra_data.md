## [Extra Data](@id config_extra)

The extra data of the configuration consists of all config options that are unique for the visualizations. 

The following extra data options exist:

### categoricalColor (boolean)
Used for `Line Plot`, indicates whether the column referenced in mappingData.color should be used nonnumerically.
Default is `true`.

### categoricalGroup (boolean)
Used for `Line Plot`, indicates whether the column referenced in mappingData.group should be used nonnumerically.
Default is `true`.

### erpBlur (number)
Used for `ERP Image`, is a number indicating how much blur is applied to the image; using Gaussian blur of the ImageFiltering module. 
Default value is `10`. Negative values deactivate the blur.

### meanPlot (boolean)
Used for `ERP Image`, indicating whether the plot should add a line plot below the ERP image, showing the mean of the data.
Default is `false`.

### pvalue (array)
Used for `Line Plot`, is an array of p-values. If array not empty, plot shows colored lines under the plot representing the p-values.
Default is `[]` (an empty array).

### sortData (boolean)
Used for `Designmatrix`, indicating whether the data is sorted; using sortslices() of Base Julia. 
Default is `false`.

Used for `ERP Image`, indicating whether the data is sorted; using sortperm() of Base Julia 
(sortperm() computes a permutation of the array's indices that puts the array into sorted order). 
Default is `false`.

### standardizeData (boolean)
Used for `Designmatrix`, indicating whether the data is standardized by pointwise division of the data with its sampled standard deviation. 
Default is `true`.

### stderror (boolean)
Used for `Line Plot`, indicating whether the plot should show a colored band showing lower and higher estimates based on the stderror. 
Default is `false`.

### topoLegend (boolean)
Used for `Line Plot`, indicating whether a topo plot is used as a legend.
Default is `false`.

### xTicks (number)
Used for `Designmatrix`, indicating the number of labels on the x-axis. Behavior if specified in configuration:
- xTicks = 0: no labels are placed.
- xTicks = 1: first possible label is placed.
- xTicks = 2: first and last possible labels are placed.
- 2 < xTicks < number of labels: xTicks-2 labels are placed between the first and last.
- xTicks ≥ number of labels: all labels are placed.
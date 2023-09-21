# [Mapping Data](@id config_mapping)

The mapping data of the configuration is used to tell the plotting functions which columns of a `DataFrame` contain which data. 
Therefore it is only used in plots with a `DataFrame` as input.

For example a Line Plot makes use of the `x` and `y` mappings.
To have our Line Plot use the "estimate" column for `x` and the "time" column for `y` we can use:
```
plot_erp(...;mapping=(;x=:estimate,))

```
Which columns are used by which plotting functions can be found in the respective tutorials in the `Tutorials: Visualizations` section.

## Multiple Options

In addition to providing a single column containing the specified data, the user can also provide a list of columns that may contain the data.
```
plot_erp(...;mapping=(;y = (:y, :yhat, :estimate)))
```
In this case the first available column will be chosen.

Some configurations for certain plots already have a default column or a list of columns set. 
This way the user may not have to set any mapping values if the `DataFrame` meets the same standards.
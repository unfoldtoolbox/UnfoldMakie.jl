# [Mapping Data](@id config_mapping)

The mapping data of the configuration is used to let the plotting functions know which columns of a `DataFrame` contain which data. 
Therefore it is only used in plots with a `DataFrame` as input.

For example a Line Plot makes use of the `x` and `y` mappings.
To have our Line Plot use the "estimate" column for `x` and the "time" column for `y` we can use:
```
plot_erp(...;mapping=(;x=:estimate,))

```
Which columns are used by which plotting function can be looked up in their respective tutorials in the `Tutorials: Visualizations` section.

## Multiple Options
In addition to providing a single column which contains the specified data, the user can also provide a list of columns which may contain the data.
```
plot_erp(...;mapping=(;y = (:y, :yhat, :estimate)))
```
In this case the first available column will be chosen.

Some configurations for certain plots already have a default column or a list of columns set. 
This way the user might not need to set any mapping values themselves, in case the `DataFrame` conforms to the same standards.
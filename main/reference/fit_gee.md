# Fit a GEE Model

Fit a GEE Model

## Usage

``` r
fit_gee(
  vars = vars_gee(),
  data,
  regression = c("logistic"),
  cor_struct = c("unstructured", "toeplitz", "compound symmetry", "auto-regressive")
)
```

## Arguments

- vars:

  (`list`)  
  see
  [`vars_gee()`](https://insightsengineering.github.io/tern.gee/reference/vars_gee.md).

- data:

  (`data.frame`)  
  input data.

- regression:

  (`string`)  
  choice of regression model.

- cor_struct:

  (`string`)  
  assumed correlation structure.

## Value

Object of class `tern_gee` as well as specific to the kind of regression
which was used.

## Details

The correlation structure can be:

- `unstructured`: No constraints are placed on the correlations.

- `toeplitz`: Assumes a banded correlation structure, i.e. the
  correlation between two time points depends on the distance between
  the time indices.

- `compound symmetry`: Constant correlation between all time points.

- `auto-regressive`: Auto-regressive order 1 correlation matrix.

## Examples

``` r
df <- fev_data
df$AVAL <- as.integer(fev_data$FEV1 > 30)

fit_gee(vars = vars_gee(arm = "ARMCD"), data = df)
#> 
#> Call:
#> geeasy::geelm(formula = formula, id = .id, waves = .waves, data = data, 
#>     family = family$object, corstr = cor_details$str, Mv = cor_details$mv, 
#>     control = family$control)
#> 
#> Coefficients:
#> (Intercept)    ARMCDTRT 
#>   2.0299313   0.7809108 
#> 
#> Degrees of Freedom: 537 Total (i.e. Null);  535 Residual
#> 
#> Scale is fixed.
#> 
#> Correlation:  Structure = unstructured    Link = identity 
#> Estimated Correlation Parameters:
#> [1] -0.032895921 -0.125407448  0.061961011 -0.030311479 -0.056769956
#> [6]  0.004383759
#> 
#> Number of clusters:   197   Maximum cluster size: 4 
#> 

fit_gee(vars = vars_gee(arm = "ARMCD"), data = df, cor_struct = "compound symmetry")
#> 
#> Call:
#> geeasy::geelm(formula = formula, id = .id, waves = .waves, data = data, 
#>     family = family$object, corstr = cor_details$str, Mv = cor_details$mv, 
#>     control = family$control)
#> 
#> Coefficients:
#> (Intercept)    ARMCDTRT 
#>   2.0643073   0.8111855 
#> 
#> Degrees of Freedom: 537 Total (i.e. Null);  535 Residual
#> 
#> Scale is fixed.
#> 
#> Correlation:  Structure = exchangeable    Link = identity 
#> Estimated Correlation Parameters:
#> [1] -0.03263465
#> 
#> Number of clusters:   197   Maximum cluster size: 4 
#> 
```

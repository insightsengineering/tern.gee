# Extract Least Square Means from a GEE Model

Extract Least Square Means from a GEE Model

## Usage

``` r
lsmeans(
  object,
  conf_level = 0.95,
  weights = "proportional",
  specs = object$vars$arm,
  ...
)

# S3 method for class 'tern_gee_logistic'
lsmeans(
  object,
  conf_level = 0.95,
  weights = "proportional",
  specs = object$vars$arm,
  ...
)
```

## Arguments

- object:

  (`tern_gee`)\
  result of
  [`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).

- conf_level:

  (`proportion`)\
  confidence level

- weights:

  (`string`)\
  type of weights to be used for the least square means, see
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html)
  for details.

- specs:

  (`string` or `formula`) specifications passed to
  [`emmeans::emmeans()`](https://rvlenth.github.io/emmeans/reference/emmeans.html)

- ...:

  additional arguments for methods

## Value

A `data.frame` with least-square means and contrasts. Additional classes
allow to dispatch downstream methods correctly, too.

## Examples

``` r
df <- fev_data
df$AVAL <- rbinom(n = nrow(df), size = 1, prob = 0.5)
fit <- fit_gee(vars = vars_gee(arm = "ARMCD"), data = df)

lsmeans(fit)
#>   ARMCD  prop_est prop_est_se prop_lower_cl prop_upper_cl   n    or_est
#> 1   PBO 0.5349901  0.02202202     0.4916075     0.5778497 420        NA
#> 2   TRT 0.5254463  0.02338787     0.4794517     0.5710132 380 0.9624085
#>   or_lower_cl or_upper_cl  log_or_est log_or_lower_cl log_or_upper_cl
#> 1          NA          NA          NA              NA              NA
#> 2   0.7471582    1.239671 -0.03831627      -0.2914784       0.2148458
#>   conf_level
#> 1       0.95
#> 2       0.95

lsmeans(fit, conf_level = 0.90, weights = "equal")
#>   ARMCD  prop_est prop_est_se prop_lower_cl prop_upper_cl   n    or_est
#> 1   PBO 0.5349901  0.02202202     0.4916075     0.5778497 420        NA
#> 2   TRT 0.5254463  0.02338787     0.4794517     0.5710132 380 0.9624085
#>   or_lower_cl or_upper_cl  log_or_est log_or_lower_cl log_or_upper_cl
#> 1          NA          NA          NA              NA              NA
#> 2   0.7782551    1.190137 -0.03831627      -0.2507009       0.1740684
#>   conf_level
#> 1        0.9
#> 2        0.9
```

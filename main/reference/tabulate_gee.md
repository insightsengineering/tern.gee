# Tabulation of a GEE Model

Functions to produce tables from a fitted GEE produced with
[`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).

## Usage

``` r
# S3 method for class 'tern_gee'
as.rtable(x, type = c("coef", "cov"), ...)

s_lsmeans_logistic(df, .in_ref_col)

a_lsmeans_logistic(df, .in_ref_col)

summarize_gee_logistic(
  lyt,
  ...,
  table_names = "lsmeans_logistic_summary",
  .stats = NULL,
  .formats = NULL,
  .indent_mods = NULL,
  .labels = NULL
)
```

## Arguments

- x:

  (`data.frame`)  
  the object which should be converted to an `rtable`.

- type:

  (`character`)  
  type of table to extract from `tern_gee` object.

- ...:

  additional arguments for methods.

- df:

  (`data.frame`)  
  data set resulting from
  [`lsmeans()`](https://insightsengineering.github.io/tern.gee/reference/lsmeans.md).

- .in_ref_col:

  (`logical`)  
  `TRUE` when working with the reference level, `FALSE` otherwise.

- lyt:

  (`layout`)  
  input layout where analyses will be added to.

- table_names:

  (`character`)  
  this can be customized in case that the same `vars` are analyzed
  multiple times, to avoid warnings from `rtables`.

- .stats:

  (`character`)  
  statistics to select for the table.

- .formats:

  (named `character` or `list`)  
  formats for the statistics.

- .indent_mods:

  (named `integer`)  
  indent modifiers for the labels.

- .labels:

  (named `character`)  
  labels for the statistics (without indent).

## Value

The functions have different purposes:

- [`as.rtable()`](https://insightsengineering.github.io/tern/latest-tag/reference/as.rtable.html)
  returns either the coefficient table or the covariance matrix as an
  `rtables` object.

- `s_lsmeans_logistic()` returns several least square mean statistics
  from the GEE.

- `a_lsmeans_logistic()` is the formatted analysis function and returns
  the formatted statistics.

- `summarize_gee_logistic()` is the analyze function and returns the
  modified `rtables` layout.

## Functions

- `as.rtable(tern_gee)`: Extracts the coefficient table or covariance
  matrix estimate from a `tern_gee` object.

- `s_lsmeans_logistic()`: Statistics function which extracts estimates
  from a
  [`lsmeans()`](https://insightsengineering.github.io/tern.gee/reference/lsmeans.md)
  data frame based on a logistic GEE model.

- `a_lsmeans_logistic()`: Formatted Analysis function which can be
  further customized by calling
  [`rtables::make_afun()`](https://insightsengineering.github.io/rtables/latest-tag/reference/make_afun.html)
  on it. It is used as `afun` in
  [`rtables::analyze()`](https://insightsengineering.github.io/rtables/latest-tag/reference/analyze.html).

- `summarize_gee_logistic()`: Analyze function for tabulating
  least-squares means estimates from logistic GEE least square mean
  results.

## Examples

``` r
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

df <- fev_data %>%
  mutate(AVAL = as.integer(fev_data$FEV1 > 30))
df_counts <- df %>%
  select(USUBJID, ARMCD) %>%
  unique()

lsmeans_df <- lsmeans(fit_gee(vars = vars_gee(arm = "ARMCD"), data = df))

s_lsmeans_logistic(lsmeans_df[1, ], .in_ref_col = TRUE)
#> $n
#> [1] 420
#> 
#> $adj_prop_se
#> [1] 0.88390403 0.01948562
#> 
#> $adj_prop_ci
#> [1] 0.8398239 0.9170515
#> attr(,"label")
#> [1] "95% CI"
#> 
#> $odds_ratio_est
#> character(0)
#> 
#> $odds_ratio_ci
#> character(0)
#> attr(,"label")
#> [1] "95% CI"
#> 
#> $log_odds_ratio_est
#> character(0)
#> 
#> $log_odds_ratio_ci
#> character(0)
#> attr(,"label")
#> [1] "95% CI"
#> 

s_lsmeans_logistic(lsmeans_df[2, ], .in_ref_col = FALSE)
#> $n
#> [1] 380
#> 
#> $adj_prop_se
#> [1] 0.94325891 0.01386798
#> 
#> $adj_prop_ci
#> [1] 0.9090296 0.9651032
#> attr(,"label")
#> [1] "95% CI"
#> 
#> $odds_ratio_est
#> [1] 2.18346
#> 
#> $odds_ratio_ci
#> [1] 1.161678 4.103974
#> attr(,"label")
#> [1] "95% CI"
#> 
#> $log_odds_ratio_est
#> [1] 0.7809108
#> 
#> $log_odds_ratio_ci
#> [1] 0.1498659 1.4119557
#> attr(,"label")
#> [1] "95% CI"
#> 
basic_table() %>%
  split_cols_by("ARMCD") %>%
  add_colcounts() %>%
  summarize_gee_logistic(
    .in_ref_col = FALSE
  ) %>%
  build_table(lsmeans_df, alt_counts_df = df_counts)
#>                                     PBO            TRT     
#>                                   (N=105)         (N=95)   
#> ———————————————————————————————————————————————————————————
#> n                                   420            380     
#> Adjusted Mean Proportion (SE)   0.88 (0.02)    0.94 (0.01) 
#>   95% CI                        (0.84, 0.92)   (0.91, 0.97)
#> Odds Ratio                           NA            2.18    
#>   95% CI                             NA        (1.16, 4.10)
#> Log Odds Ratio                       NA            0.78    
#>   95% CI                             NA        (0.15, 1.41)
```

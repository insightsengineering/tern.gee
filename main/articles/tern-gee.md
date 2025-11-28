# Introduction to tern.gee

## Introduction

Generalized Estimating Equations (GEEs) are mainly used for modeling
longitudinal binary or count endpoints from clinical trials. Within this
package, a GEE is used to estimate the parameters of a generalized
linear model that includes as fixed effects the variables: treatment
arm, categorical visit, and other covariates for adjustment (e.g. age,
sex, race). The covariance structure of the residuals can take on
different forms. Often, an unstructured (i.e. saturated
parameterization) covariance matrix is assumed which can be represented
by random effects in the model.

This vignette shows the general purpose and syntax of the `tern.gee` R
package which provides an interface for GEEs within the `tern`
framework. This package builds upon some of the GEE functionality
included in the `geepack` and `geeasy` R packages. Within this package,
we have implemented GEEs in R in such a way that they can easily be
embedded into a `shiny` application. See
[`teal.modules.clinical::tm_a_gee()`](https://insightsengineering.github.io/teal.modules.clinical/latest-tag/reference/tm_a_gee.html)
and the [`teal.modules.clinical`
package](https://insightsengineering.github.io/teal.modules.clinical/)
for more details about using this code inside a `shiny` application.

------------------------------------------------------------------------

## Example

Here we will demonstrate how the `tern.gee` package functionality can be
used to fit a GEE model and tabulate its output.

### Setup

Our sample dataset, `fev_data`, is available in the `tern.gee` package
and consists of seven variables: subject ID (`USUBJID`), visit number
(`AVISIT`), treatment (`ARMCD` = TRT or PBO), 3-category `RACE`, `SEX`,
FEV1 at baseline (%) (`FEV1_BL`), and FEV1 at study visits (%) (`FEV1`).
Additionally we create an arbitrary binary variable `FEV1_BINARY` for
our analysis which takes a value of 1 where `FEV1 > 30` and 0 otherwise.
FEV1 (forced expired volume in one second) is a measure of how quickly
the lungs can be emptied. Low levels of FEV1 may indicate chronic
obstructive pulmonary disease (COPD). The scientific question at hand is
whether treatment leads to an increase in FEV1 over time after adjusting
for baseline covariates.

``` r
library(tern.gee)
fev_data$FEV1_BINARY <- as.integer(fev_data$FEV1 > 30)
head(fev_data)
#> # A tibble: 6 × 8
#>   USUBJID AVISIT ARMCD RACE                      SEX   FEV1_BL  FEV1 FEV1_BINARY
#>   <fct>   <fct>  <fct> <fct>                     <fct>   <dbl> <dbl>       <int>
#> 1 PT1     VIS1   TRT   Black or African American Fema…    25.3  NA            NA
#> 2 PT1     VIS2   TRT   Black or African American Fema…    25.3  40.0           1
#> 3 PT1     VIS3   TRT   Black or African American Fema…    25.3  NA            NA
#> 4 PT1     VIS4   TRT   Black or African American Fema…    25.3  20.5           0
#> 5 PT2     VIS1   PBO   Asian                     Male     45.0  NA            NA
#> 6 PT2     VIS2   PBO   Asian                     Male     45.0  31.5           1
```

### Model Fitting

Fitting a GEE model is easy when you use `tern.gee`. By default, the
model fitting function
[`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md)
assumes unstructured correlation and proportional weights when
calculating LS means, and fits a logistic regression model. Currently
only logistic regression has been implemented as an available regression
model when using
[`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).
In future the package will be extended to include other models such as
Poisson regression, etc. as alternative options.

``` r
fev_fit <- fit_gee(
  vars = list(
    response = "FEV1_BINARY",
    covariates = c("RACE", "SEX", "FEV1_BL"),
    arm = "ARMCD",
    id = "USUBJID",
    visit = "AVISIT"
  ),
  data = fev_data
)
#> Registered S3 methods overwritten by 'geeasy':
#>   method       from   
#>   drop1.geeglm MESS   
#>   drop1.geem   MESS   
#>   plot.geeglm  geepack
fev_fit
#> 
#> Call:
#> geeasy::geelm(formula = formula, id = .id, waves = .waves, data = data, 
#>     family = family$object, corstr = cor_details$str, Mv = cor_details$mv, 
#>     control = family$control)
#> 
#> Coefficients:
#>                   (Intercept)                      ARMCDTRT 
#>                   -0.20061892                    0.74524533 
#> RACEBlack or African American                     RACEWhite 
#>                    0.11627212                    1.38199917 
#>                     SEXFemale                       FEV1_BL 
#>                   -0.14521343                    0.05257141 
#> 
#> Degrees of Freedom: 537 Total (i.e. Null);  531 Residual
#> 
#> Scale is fixed.
#> 
#> Correlation:  Structure = unstructured    Link = identity 
#> Estimated Correlation Parameters:
#> [1] -0.046922366 -0.130175920  0.071402079 -0.126586549 -0.062642853
#> [6]  0.006795836
#> 
#> Number of clusters:   197   Maximum cluster size: 4
```

The resulting object consists of many pieces of information pertaining
to the model such as the estimated coefficients, correlation parameters,
etc. Additionally, the
[`lsmeans()`](https://insightsengineering.github.io/tern.gee/reference/lsmeans.md)
function from `tern.gee` can be used to extract the least squares means
from any GEE model created using
[`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).

``` r
fev_lsmeans <- lsmeans(fev_fit, data = fev_data)
fev_lsmeans
#>   ARMCD  prop_est prop_est_se prop_lower_cl prop_upper_cl   n   or_est
#> 1   PBO 0.9054200  0.01904206     0.8608217     0.9367768 420       NA
#> 2   TRT 0.9527634  0.01193578     0.9229565     0.9713959 380 2.106958
#>   or_lower_cl or_upper_cl log_or_est log_or_lower_cl log_or_upper_cl conf_level
#> 1          NA          NA         NA              NA              NA       0.95
#> 2    1.125774    3.943307  0.7452453        0.118471         1.37202       0.95
```

Based on the output, there is evidence to support that treatment leads
to an increase in FEV1 over placebo. The GEE model can be refined by
using different correlation structures and weighting schemes.

### Tabulation

After fitting a GEE model and extracting the LS means you may want to
display your results in a table. The `tern.gee` package contains
functionality to summarize the results of a
[`lsmeans()`](https://insightsengineering.github.io/tern.gee/reference/lsmeans.md)
object in an `rtable` structure, using additional functions from the
[`rtables` package](https://insightsengineering.github.io/rtables/).

``` r
fev_counts <- fev_data %>%
  dplyr::select(USUBJID, ARMCD) %>%
  unique()

fev_gee_table <- basic_table(show_colcounts = TRUE) %>%
  split_cols_by("ARMCD", ref_group = "PBO") %>%
  summarize_gee_logistic() %>%
  build_table(fev_lsmeans, alt_counts_df = fev_counts)

fev_gee_table
#>                                     PBO            TRT     
#>                                   (N=105)         (N=95)   
#> ———————————————————————————————————————————————————————————
#> n                                   420            380     
#> Adjusted Mean Proportion (SE)   0.91 (0.02)    0.95 (0.01) 
#>   95% CI                        (0.86, 0.94)   (0.92, 0.97)
#> Odds Ratio                                         2.11    
#>   95% CI                                       (1.13, 3.94)
#> Log Odds Ratio                                     0.75    
#>   95% CI                                       (0.12, 1.37)
```

First we create a table `fev_counts` to get the number of unique
subjects receiving each treatment. These counts are displayed in the
header of the table under each of the column names by specifying
`show_colcounts = TRUE` when initializing the table via the
`basic_table()` function. The table is split by arm (`ARMCD`), with
`PBO` specified as the reference group to compare the `TRT` group to.
Then the
[`summarize_gee_logistic()`](https://insightsengineering.github.io/tern.gee/reference/tabulate_gee.md)
function from `tern.gee` is applied. Finally, the `build_table()`
function builds the `rtable` using our LS means dataset with
`fev_counts` providing the counts of unique subjects in each arm.

# Set Variables to Use in GEE Model

Set Variables to Use in GEE Model

## Usage

``` r
vars_gee(
  response = "AVAL",
  covariates = c(),
  id = "USUBJID",
  arm = "ARM",
  visit = "AVISIT"
)
```

## Arguments

- response:

  (`character`)  
  name of response variable.

- covariates:

  (`character`)  
  vector of names of variables to use as covariates.

- id:

  (`character`)  
  name of variable to use to identify unique IDs.

- arm:

  (`character`)  
  name of arm variable.

- visit:

  (`character`)  
  name of visit variable.

## Value

A list of variables that can be used as the `vars` argument in
[`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).

## Examples

``` r
vars_gee()
#> $response
#> [1] "AVAL"
#> 
#> $covariates
#> NULL
#> 
#> $id
#> [1] "USUBJID"
#> 
#> $arm
#> [1] "ARM"
#> 
#> $visit
#> [1] "AVISIT"
#> 

vars_gee(
  response = "CHG",
  covariates = c("SEX", "RACE"),
  id = "SUBJID",
  arm = "ARMCD",
  visit = "AVISITN"
)
#> $response
#> [1] "CHG"
#> 
#> $covariates
#> [1] "SEX"  "RACE"
#> 
#> $id
#> [1] "SUBJID"
#> 
#> $arm
#> [1] "ARMCD"
#> 
#> $visit
#> [1] "AVISITN"
#> 
```

# Methods for GEE Models

Additional methods which can simplify working with the GEE result
object.

## Usage

``` r
# S3 method for class 'tern_gee'
VarCorr(x, sigma = 1, ...)

# S3 method for class 'tern_gee'
QIC(object, ...)
```

## Arguments

- x:

  (`tern_gee`)  
  result of
  [`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).

- sigma:

  an optional numeric value used as a multiplier for the standard
  deviations. The default is `x$sigma` or `1` depending on
  [`class`](https://rdrr.io/r/base/class.html)`(x)`.

- ...:

  further optional arguments passed to other methods (none for the
  methods documented here).

- object:

  (`tern_gee`)  
  result of
  [`fit_gee()`](https://insightsengineering.github.io/tern.gee/reference/fit_gee.md).

## Value

`VarCorr()` returns the estimated covariance matrix, and `QIC()` returns
the QIC value.

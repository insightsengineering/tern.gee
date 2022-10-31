# tern.gee

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

## Overview

`tern.gee` provides an interface for generalized estimating equations (GEE) within the
[`tern`](https://insightsengineering.github.io/tern) framework
to produce commonly used tables (using [`rtables`](https://roche.github.io/rtables)) and graphs.
It builds on the R-package `geepack` for the actual GEE calculations.

## When to use this package

If you would like to use the [`tern`](https://insightsengineering.github.io/tern) framework for
tabulation and graphs, then this package is ideal for your GEE fits.
However if you use another reporting framework then it will be better to directly use
`geepack` and perform the tabulation and plots differently.

## Main Features

* Fitting of GEE models to continuous longitudinal data collected over several time points
  (called visits) and optionally treatment arms.
* Tabulation of least square means per visit and treatment arm.
* Tabulation of the covariance matrix estimate.

## Installation

### GitHub

It is recommended that you [create and use a Github PAT](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) to install the latest version of this package. Once you have the PAT, run the following:

```r
Sys.setenv(GITHUB_PAT = "your_access_token_here")
if (!require("remotes")) install.packages("remotes")
remotes::install_github("insightsengineering/tern.gee@*release")
```

### `NEST` distribution

A stable release of all `NEST` packages is also available [here](https://github.com/insightsengineering/depository#readme).

## Getting started

You can get started by trying out the example:

```r
library(tern.gee)

fev_data$FEV1_BINARY <- as.integer(fev_data$FEV1 > 30)

fit <- fit_gee(
  vars = list(
    response = "FEV1_BINARY",
    covariates = c("RACE", "SEX"),
    arm = "ARMCD",
    id = "USUBJID",
    visit = "AVISIT"
  ),
  data = fev_data
)
```

This specifies a GEE with the `FEV1_BINARY` outcome and the `RACE` and `SEX` covariates for 
subjects identified by `USUBJID` and treatment arm `ARMCD` observed over time points identified 
by `AVISIT` in the `fev_data` data set. By deafult, logistic regression is used and an unstructured 
covariance matrix is assumed. The least square means assume equal weights for factor combinations.

## Stargazers

### Current

[![Stargazers repo roster for @insightsengineering/tern.gee](https://reporoster.com/stars/insightsengineering/tern.gee)](https://github.com/insightsengineering/tern.gee/stargazers)
[![Forkers repo roster for @insightsengineering/tern.gee](https://reporoster.com/forks/insightsengineering/tern.gee)](https://github.com/insightsengineering/tern.gee/network/members)

### Over time

[![Stargazers over time](https://starchart.cc/insightsengineering/tern.gee.svg)](https://starchart.cc/insightsengineering/tern.gee)

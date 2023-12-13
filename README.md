# tern.gee

<!-- start badges -->
[![Check 🛠](https://github.com/insightsengineering/tern.gee/actions/workflows/check.yaml/badge.svg)](https://insightsengineering.github.io/tern.gee/main/unit-test-report/)
[![Docs 📚](https://github.com/insightsengineering/tern.gee/actions/workflows/docs.yaml/badge.svg)](https://insightsengineering.github.io/tern.gee/)
[![Release 🎈](https://github.com/insightsengineering/tern.gee/actions/workflows/release.yaml/badge.svg)](https://github.com/insightsengineering/tern.gee/releases)
[![Code Coverage 📔](https://raw.githubusercontent.com/insightsengineering/tern.gee/_xml_coverage_reports/data/main/badge.svg)](https://insightsengineering.github.io/tern.gee/main/coverage-report/)

![GitHub forks](https://img.shields.io/github/forks/insightsengineering/tern.gee?style=social)
![GitHub Repo stars](https://img.shields.io/github/stars/insightsengineering/tern.gee?style=social)

![GitHub commit activity](https://img.shields.io/github/commit-activity/m/insightsengineering/tern.gee)
![GitHub contributors](https://img.shields.io/github/contributors/insightsengineering/tern.gee)
![GitHub last commit](https://img.shields.io/github/last-commit/insightsengineering/tern.gee)
![GitHub pull requests](https://img.shields.io/github/issues-pr/insightsengineering/tern.gee)
![GitHub repo size](https://img.shields.io/github/repo-size/insightsengineering/tern.gee)
![GitHub language count](https://img.shields.io/github/languages/count/insightsengineering/tern.gee)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Current Version](https://img.shields.io/github/r-package/v/insightsengineering/tern.gee/main?color=purple\&label=package%20version)](https://github.com/insightsengineering/tern.gee/tree/main)
[![Open Issues](https://img.shields.io/github/issues-raw/insightsengineering/tern.gee?color=red\&label=open%20issues)](https://github.com/insightsengineering/tern.gee/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc)
<!-- end badges -->

## Overview

`tern.gee` provides an interface for generalized estimating equations (GEE) within the
[`tern`](https://insightsengineering.github.io/tern) framework
to produce commonly used tables (using [`rtables`](https://insightsengineering.github.io/rtables)) and graphs.
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

`tern.gee` is available on CRAN and you can install the latest released version with:

``` r
install.packages("tern.gee")
```

or you can install the latest development version directly from GitHub by running the following:

``` r
if (!require("remotes")) install.packages("remotes")
remotes::install_github("insightsengineering/tern.gee")
```

Note that it is recommended you [create and use a `GITHUB_PAT`](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) if installing from GitHub.

## Getting started

You can get started by trying out the example:

```r
library(tern.gee)

fev_data$FEV1_BINARY <- as.integer(fev_data$FEV1 > 30)
fev_counts <- fev_data %>%
  dplyr::select(USUBJID, ARMCD) %>%
  unique()

gee_fit <- fit_gee(
  vars = list(
    response = "FEV1_BINARY",
    covariates = c("RACE", "SEX"),
    arm = "ARMCD",
    id = "USUBJID",
    visit = "AVISIT"
  ),
  data = fev_data
)

lsmeans_df <- lsmeans(gee_fit, data = fev_data)

basic_table(show_colcounts = TRUE) %>%
  split_cols_by("ARMCD", ref_group = "PBO") %>%
  summarize_gee_logistic() %>%
  build_table(lsmeans_df, alt_counts_df = fev_counts)
```

This specifies a GEE with the `FEV1_BINARY` outcome and the `RACE` and `SEX` covariates for subjects identified by `USUBJID` and treatment arm `ARMCD` observed over time points identified by `AVISIT` in the `fev_data` data set. By default, logistic regression is used and an unstructured covariance matrix is assumed. The least square means assume equal weights for factor combinations.

For more information on how GEE models and their `rtables` tables are created see [the introduction vignette](https://insightsengineering.github.io/tern.gee/main/articles/tern-gee.html).

## Stargazers

### Current

[![Stargazers repo roster for @insightsengineering/tern.gee](https://reporoster.com/stars/insightsengineering/tern.gee)](https://github.com/insightsengineering/tern.gee/stargazers)
[![Forkers repo roster for @insightsengineering/tern.gee](https://reporoster.com/forks/insightsengineering/tern.gee)](https://github.com/insightsengineering/tern.gee/network/members)

### Over time

[![Stargazers over time](https://starchart.cc/insightsengineering/tern.gee.svg)](https://starchart.cc/insightsengineering/tern.gee)

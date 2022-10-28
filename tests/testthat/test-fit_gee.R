# build_formula ----

test_that("build_formula builds the correct formula", {
  vars <- list(response = "AVAL", id = "USUBJID", arm = "ARMCD", visit = "AVISIT", covariates = c("RACE", "SEX"))
  result <- as.character(build_formula(vars))
  expected <- as.character(AVAL ~ ARMCD + RACE + SEX)
  expect_identical(result, expected)
})

test_that("build_formula works without covariates", {
  result <- expect_silent(build_formula(vars_gee()))
  expected <- AVAL ~ ARM
  expect_equal(result, expected, ignore_attr = TRUE)
})

# build_family ----

test_that("build_family returns the correct class", {
  result <- as.character(build_family("logistic"))[2]
  expected <- "tern_gee_logistic"
  expect_identical(result, expected)
})

test_that("build_family gives error message if incorrect regression type is given", {
  expect_error(build_family("BLAHHH"), "regression type BLAHHH not supported")
})

# build_cor_details ----

test_that("build_cor_details returns the correct correlation details", {
  result <- as.character(build_cor_details("unstructured", fev_vars, fev_data))
  expected <- c("unstructured", "1")
  expect_identical(result, expected)
})

test_that("build_cor_details gives error message if incorrect correlation structure is given", {
  expect_error(build_cor_details("BLAHHH", fev_vars, fev_data), "correlation structure BLAHHH not available")
})

# fit_gee ----

## logistic ----

test_that("unstructured", {
  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  ))
  expect_class(result, c("tern_gee_logistic", "tern_gee", "geelm"))
})

test_that("auto-regressive", {
  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "auto-regressive"
  ))
  expect_class(result, c("tern_gee_logistic", "tern_gee", "geelm"))
})

test_that("compound symmetry", {
  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "compound symmetry"
  ))
  expect_class(result, c("tern_gee_logistic", "tern_gee", "geelm"))
})

test_that("toeplitz", {
  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "toeplitz"
  ))
  expect_class(result, c("tern_gee_logistic", "tern_gee", "geelm"))
})

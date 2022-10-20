# build_formula ----

test_that("build_formula works without covariates", {
  result <- expect_silent(build_formula(vars_gee()))
  expected <- AVAL ~ ARM
  expect_equal(result, expected, ignore_attr = TRUE)
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

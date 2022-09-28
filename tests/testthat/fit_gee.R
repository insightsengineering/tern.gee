# fit_gee ----

## logistic ----

test_that("unstructured", {
  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  ))
  expect_class(result, c("tern_gee_logistic", "tern_gee", "gee", "glm"))
})

test_that("auto-regressive", {
  skip("auto-regressive does not work yet")

  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "auto-regressive"
  ))
  # error:
  # cgee: M-dependence, M=1, but clustsize=1
  expect_class(result, c("tern_gee_logistic", "tern_gee", "gee", "glm"))
})

test_that("compound symmetry", {
  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "compound symmetry"
  ))
  expect_class(result, c("tern_gee_logistic", "tern_gee", "gee", "glm"))
})

test_that("toeplitz", {
  skip("toeplitz does not work yet")

  result <- expect_silent(fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "toeplitz"
  ))
  # error:
  # cgee: M-dependence, M=3, but clustsize=2
  expect_class(result, c("tern_gee_logistic", "tern_gee", "gee", "glm"))
})

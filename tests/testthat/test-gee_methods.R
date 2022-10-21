model <- fit_gee(
  vars = fev_vars,
  data = fev_data,
  regression = "logistic",
  cor_struct = "unstructured"
)

test_that("vcov works as expected", {
  result <- expect_silent(vcov(model))
  expect_matrix(result, nrows = 4, ncols = 4)
})

test_that("VarCorr works as expected for unstructured correlation structure", {
  model <- fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  )

  result <- expect_silent(VarCorr(model))
  expect_true(all(eigen(result)$values > 0))
})

test_that("VarCorr works as expected for compound symmetry correlation structure", {
  model <- fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "compound symmetry"
  )

  result <- expect_silent(VarCorr(model))
  expect_true(all(eigen(result)$values > 0))
})

test_that("VarCorr works as expected for AR1 correlation structure", {
  model <- fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "auto-regressive"
  )

  result <- expect_silent(VarCorr(model))
  expect_true(all(eigen(result)$values > 0))
})

test_that("VarCorr works as expected for Toeplitz correlation structure", {
  model <- fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "toeplitz"
  )

  result <- expect_silent(VarCorr(model))
  expect_true(all(eigen(result)$values > 0))
})

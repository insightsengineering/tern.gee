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

test_that("VarCorr works as expected", {
  result <- expect_silent(VarCorr(model))
})

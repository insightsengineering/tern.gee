test_that("fit_gee works in logistic regression example", {
  fev_data$FEV1_BINARY <- as.integer(fev_data$FEV1 > 30)
  result <- fit_gee(
    vars = vars_gee(
      response = "FEV1_BINARY",
      covariates = "RACE",
      arm = "ARMCD",
      id = "USUBJID",
      visit = "AVISIT"
    ),
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  )
})

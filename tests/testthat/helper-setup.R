# example ----

fev_data$FEV1_BINARY <- as.integer(fev_data$FEV1 > 30)
fev_vars <- vars_gee(
  response = "FEV1_BINARY",
  covariates = "RACE",
  arm = "ARMCD",
  id = "USUBJID",
  visit = "AVISIT"
)

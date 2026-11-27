test_that("lsmeans works for logistic model", {
  model <- fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  )

  result <- lsmeans(model)
  expect_data_frame(result)
  expect_class(result, "lsmeans_logistic")
  expect_named(result, c(
    "ARMCD", "prop_est", "prop_est_se", "prop_lower_cl", "prop_upper_cl", "n",
    "or_est", "or_lower_cl", "or_upper_cl", "log_or_est", "log_or_lower_cl", "log_or_upper_cl",
    "conf_level"
  ))
  expect_identical(nrow(result), 2L)
})

test_that("lsmeans uses conf_level for the proportion confidence intervals", {
  model <- fit_gee(
    vars = fev_vars,
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  )

  result <- lsmeans(model, conf_level = 0.8)
  expected <- as.data.frame(stats::confint(
    emmeans::emmeans(model, specs = "ARMCD", weights = "proportional", type = "response", data = model$data),
    level = 0.8
  ))
  expect_equal(result$prop_lower_cl, expected$lower.CL)
  expect_equal(result$prop_upper_cl, expected$upper.CL)
})

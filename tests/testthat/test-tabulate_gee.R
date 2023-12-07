dat_adsl <- fev_data %>%
  dplyr::select(USUBJID, ARMCD) %>%
  dplyr::distinct()

model <- fit_gee(
  vars = fev_vars,
  data = fev_data,
  regression = "logistic",
  cor_struct = "unstructured"
)

# to do: finish test once h_gee_coef is working correctly
# test_that("h_gee_coef works as expected", {
# result <- expect_silent(h_gee_coef(model))
# result2 <- as.rtable(model, type = "coef", format = "xx.xxxx")
# expect_identical(result, result2)
#
# result_matrix <- to_string_matrix(result)
# expected_matrix <- structure(
#   c(
#   ),
#   dim = c()
# )
# expect_identical(result_matrix, expected_matrix)
# })

test_that("h_gee_cov works as expected", {
  result <- expect_silent(h_gee_cov(model))
  result2 <- as.rtable(model, type = "cov", format = "xx.xxxx")
  expect_identical(result, result2)

  expect_snapshot(result)
})

test_that("s_lsmeans_logistic works as expected when not in reference column", {
  result <- s_lsmeans_logistic(lsmeans(model)[2, ], FALSE)
  expected <- list(
    n = 380L,
    adj_prop_se = c(0.94694895, 0.01347376),
    adj_prop_ci = formatters::with_label(c(0.9134350, 0.9679432), label = "95% CI"),
    odds_ratio_est = 1.970852,
    odds_ratio_ci = formatters::with_label(c(1.031652, 3.765083), label = "95% CI"),
    log_odds_ratio_est = 0.6784657,
    log_odds_ratio_ci = formatters::with_label(c(0.03116157, 1.32576989), label = "95% CI")
  )
  expect_equal(result, expected, tolerance = 1e-2)
})

test_that("s_mmrm_lsmeans works as expected when in reference column", {
  result <- s_lsmeans_logistic(lsmeans(model)[1, ], TRUE)
  expected <- list(
    n = 420L,
    adj_prop_se = c(0.9005656, 0.0198212),
    adj_prop_ci = formatters::with_label(c(0.8544189, 0.9332277), label = "95% CI"),
    odds_ratio_est = character(0),
    odds_ratio_ci = formatters::with_label(character(0), label = "95% CI"),
    log_odds_ratio_est = character(0),
    log_odds_ratio_ci = formatters::with_label(character(0), label = "95% CI")
  )
  expect_equal(result, expected, tolerance = 1e-2)
})

test_that("summarize_gee_logistic works as expected with covariates in the model", {
  result <- basic_table() %>%
    split_cols_by("ARMCD", ref_group = model$ref_level) %>%
    add_colcounts() %>%
    summarize_gee_logistic() %>%
    build_table(
      df = lsmeans(model),
      alt_counts_df = dat_adsl
    )

  expect_snapshot(result)
})

test_that("summarize_gee_logistic works as expected with no covariates in the model", {
  fev_vars_nocov <- vars_gee(
    response = "FEV1_BINARY",
    arm = "ARMCD",
    id = "USUBJID",
    visit = "AVISIT"
  )
  model <- fit_gee(
    vars = fev_vars_nocov,
    data = fev_data,
    regression = "logistic",
    cor_struct = "unstructured"
  )
  result <- basic_table() %>%
    split_cols_by("ARMCD", ref_group = model$ref_level) %>%
    add_colcounts() %>%
    summarize_gee_logistic() %>%
    build_table(
      df = lsmeans(model),
      alt_counts_df = dat_adsl
    )

  expect_snapshot(result)
})

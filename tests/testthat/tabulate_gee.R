model <- fit_gee(
  vars = fev_vars,
  data = fev_data,
  regression = "logistic",
  cor_struct = "unstructured"
)

test_that("h_gee_coef works", {
  result <- expect_silent(h_gee_coef(model))
  # to do: add expectation
})

test_that("h_gee_cov works", {
  result <- expect_silent(h_gee_cov(model))
  # to do: add expectation
})

test_that("summarize_gee_logistic works", {
  dat_adsl <- fev_data %>%
    dplyr::select(USUBJID, ARMCD) %>%
    dplyr::distinct()
  result <- basic_table() %>%
    split_cols_by("ARMCD", ref_group = model$ref_level) %>%
    add_colcounts() %>%
    summarize_gee_logistic() %>%
    build_table(
      df = lsmeans(model),
      alt_counts_df = dat_adsl
    )
  # to do: add expectation
})

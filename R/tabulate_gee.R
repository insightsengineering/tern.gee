#' Tabulation of a GEE Model
#'
#' Functions to produce tables from a fitted GEE produced with [fit_gee()].
#'
#' @name tabulate_gee
NULL

#' @importFrom tern as.rtable
#' @export
tern::as.rtable

#' @exportS3Method
#' @describeIn tabulate_gee Extracts the coefficient table or covariance matrix estimate from a `tern_gee` object.
as.rtable.tern_gee <- function(x, # nolint
                               type = c("coef", "cov"),
                               ...) {
  type <- match.arg(type)
  switch(type,
    coef = h_gee_coef(x, ...),
    cov = h_gee_cov(x, ...)
  )
}

#' @keywords internal
h_gee_coef <- function(x, format = "xx.xxxx", conf_level = 0.95, ...) {
  fixed_table <- as.data.frame(stats::coef(summary(x)))
  assert_number(conf_level, lower = 0.001, upper = 0.999)

  fixed_table[["Std. Error"]] <- fixed_table[["Robust S.E."]]
  fixed_table[["z value"]] <- fixed_table[["Robust z"]]
  fixed_table[["Pr(>|z|)"]] <- 2 * stats::pnorm(abs(fixed_table[["z value"]]), lower.tail = FALSE)
  q <- stats::qnorm((1 + conf_level) / 2)
  ci_string <- tern::f_conf_level(conf_level)
  lower_string <- paste("Lower", ci_string)
  upper_string <- paste("Upper", ci_string)
  fixed_table[[lower_string]] <- fixed_table$Estimate - q * fixed_table[["Std. Error"]]
  fixed_table[[paste("Upper", ci_string)]] <- fixed_table$Estimate + q * fixed_table[["Std. Error"]]

  est_se_ci_table <- as.rtable(
    fixed_table[, c("Estimate", "Std. Error", lower_string, upper_string)],
    format = format
  )
  z_table <- as.rtable(fixed_table[, c("z value"), drop = FALSE], format = format)
  pvalue_table <- as.rtable(fixed_table[, "Pr(>|z|)", drop = FALSE], format = "x.xxxx | (<0.0001)")

  cbind_rtables(est_se_ci_table, z_table, pvalue_table)
}

#' @keywords internal
h_gee_cov <- function(x, format = "xx.xxxx") {
  cov_estimate <- VarCorr(x)
  as.rtable(as.data.frame(cov_estimate), format = format)
}

# lsmeans_logistic ----

#' @describeIn tabulate_gee Statistics function which extracts estimates from a
#'   [lsmeans()] data frame based on a logistic GEE model.
#'
#' @param df (`data.frame`)\cr data set resulting from [lsmeans()].
#' @param .in_ref_col (`logical`)\cr `TRUE` when working with the reference level, `FALSE` otherwise.
#'
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' df <- fev_data %>%
#'   mutate(AVAL = as.integer(fev_data$FEV1 > 30))
#' df_counts <- df %>%
#'   select(USUBJID, ARMCD) %>%
#'   unique()
#'
#' lsmeans_df <- lsmeans(fit_gee(vars = vars_gee(arm = "ARMCD"), data = df))
#'
#' s_lsmeans_logistic(lsmeans_df[1,], .in_ref_col = TRUE)
#'
#' s_lsmeans_logistic(lsmeans_df[2,], .in_ref_col = FALSE)
s_lsmeans_logistic <- function(df, .in_ref_col) {
  if_not_ref <- function(x) `if`(.in_ref_col, character(), x)
  list(
    n = df$n,
    adj_prop_se = c(df$prop_est, df$prop_est_se), # to be confirmed
    adj_prop_ci = formatters::with_label(c(df$prop_lower_cl, df$prop_upper_cl), f_conf_level(df$conf_level)),
    odds_ratio_est = if_not_ref(df$or_est),
    odds_ratio_ci = formatters::with_label(
      if_not_ref(c(df$or_lower_cl, df$or_upper_cl)),
      f_conf_level(df$conf_level)
    ),
    log_odds_ratio_est = if_not_ref(df$log_or_est),
    log_odds_ratio_ci = formatters::with_label(
      if_not_ref(c(df$log_or_lower_cl, df$log_or_upper_cl)),
      f_conf_level(df$conf_level)
    )
  )
}

## a_lsmeans_logistic ----

#' @describeIn tabulate_gee Formatted Analysis function which can be further customized by calling
#'   [rtables::make_afun()] on it. It is used as `afun` in [rtables::analyze()].
#'
#' @export
a_lsmeans_logistic <- make_afun(
  s_lsmeans_logistic,
  .labels = c(
    adj_prop_se = "Adjusted Mean Proportion (SE)",
    odds_ratio_est = "Odds Ratio",
    log_odds_ratio_est = "Log Odds Ratio"
  ),
  .formats = c(
    n = "xx.",
    adj_prop_se = sprintf_format("%.2f (%.2f)"),
    adj_prop_ci = "(xx.xx, xx.xx)",
    odds_ratio_est = "xx.xx",
    odds_ratio_ci = "(xx.xx, xx.xx)",
    log_odds_ratio_est = "xx.xx",
    log_odds_ratio_ci = "(xx.xx, xx.xx)"
  ),
  .indent_mods = c(
    adj_prop_ci = 1L,
    odds_ratio_ci = 1L,
    log_odds_ratio_ci = 1L
  ),
  .null_ref_cells = FALSE
)

# Note: In production it would be nice to allow an S3 dispatch according to the
# class of the lsmeans input, however for now in the prototype we keep it simple.
# see later then to tern::summarize_variables for how to do that.

#' @describeIn tabulate_gee Analyze function for tabulating least-squares means estimates
#'   from logistic GEE least square mean results.
#'
#' @param lyt (`layout`)\cr input layout where analyses will be added to.
#' @param table_names (`character`)\cr this can be customized in case that the same `vars`
#'   are analyzed multiple times, to avoid warnings from `rtables`.
#' @param .stats (`character`)\cr statistics to select for the table.
#' @param .formats (named `character` or `list`)\cr formats for the statistics.
#' @param .indent_mods (named `integer`)\cr indent modifiers for the labels.
#' @param .labels (named `character`)\cr labels for the statistics (without indent).
#'
#' @export
#'
#' @examples
#' basic_table() %>%
#'   split_cols_by("ARMCD") %>%
#'   add_colcounts() %>%
#'   summarize_gee_logistic(
#'     .in_ref_col = FALSE
#'   ) %>%
#'   build_table(lsmeans_df, alt_counts_df = df_counts)
summarize_gee_logistic <- function(lyt,
                                   ...,
                                   table_names = "lsmeans_logistic_summary",
                                   .stats = NULL,
                                   .formats = NULL,
                                   .indent_mods = NULL,
                                   .labels = NULL) {
  afun <- make_afun(
    a_lsmeans_logistic,
    .stats = .stats,
    .formats = .formats,
    .indent_mods = .indent_mods,
    .labels = .labels
  )
  analyze(
    lyt = lyt,
    vars = "n",
    afun = afun,
    table_names = table_names,
    extra_args = list(...)
  )
}

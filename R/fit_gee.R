vars_gee <- function(response = "AVAL",
                     covariates = c(),
                     id = "USUBJID",
                     arm = "ARM",
                     visit = "AVISIT") {
  list(
    response = response,
    covariates = covariates,
    id = id,
    arm = arm,
    visit = visit
  )
}

#' @keywords internal
build_formula <- function(vars) {
  assert_list(vars)
  arm_part <- if (is.null(vars$arm)) NULL else vars$arm
  rhs_formula <- paste(
    c(arm_part, vars$covariates),
    collapse = " + "
  )
  stats::as.formula(paste(
    vars$response,
    "~",
    rhs_formula
  ))
}

#' @keywords internal
build_family <- function(regression) {
  assert_string(regression)

  result_object <- switch(regression,
    logistic = stats::binomial(link = "logit"),
    stop(paste("regression type", regression, "not supported"))
  )

  result_class <- paste0("tern_gee_", regression)

  list(
    object = result_object,
    class = result_class,
    control = geeasy::geelm.control(scale.fix = TRUE)
  )
}

#' @keywords internal
build_cor_details <- function(cor_str, vars, data) {
  assert_string(cor_str)
  assert_list(vars)
  assert_data_frame(data)

  result_str <- switch(cor_str,
    "unstructured" = "unstructured",
    "toeplitz" = "m-dependent",
    "compound symmetry" = "exchangeable",
    "auto-regressive" = "ar1",
    stop(paste("correlation structure", cor_str, "not available"))
  )

  result_mv <- switch(cor_str,
    "unstructured" = 1,
    "toeplitz" = nlevels(data[[vars$visit]]) - 1,
    "compound symmetry" = 1,
    "auto-regressive" = 1
  )

  list(
    str = result_str,
    mv = result_mv
  )
}

order_data <- function(data, vars) {
  assert_data_frame(data)
  assert_list(vars)

  if (is.character(data[[vars$visit]])) {
    message(paste("visit variable", vars$visit, "will be coerced to factor for ordering"))
    message("order is:")
    data[[vars$visit]] <- factor(data[[vars$visit]])
    cat(toString(levels(data[[vars$visit]])))
  }
  if (is.factor(data[[vars$id]]) || is.character(data[[vars$id]])) {
    data[[vars$id]] <- as.integer(as.factor(data[[vars$id]]))
  }
  assert_numeric(data[[vars$id]])

  right_order <- order(data[[vars$id]], data[[vars$visit]])
  data[right_order, ]
}

#' Fit a GEE Model
#'
#' @param vars (`list`)\cr see [vars_gee()].
#' @param data (`data.frame`)\cr input data.
#' @param regression (`string`)\cr choice of regression model.
#' @param cor_struct (`string`)\cr assumed correlation structure.
#'
#' @details The correlation structure can be:
#' * `unstructured`: No constraints are placed on the correlations.
#' * `toeplitz`: Assumes a banded correlation structure, i.e. the correlation
#'    between two time points depends on the distance between the time indices.
#' * `compound symmetry`: Constant correlation between all time points.
#' * `auto-regressive`: Auto-regressive order 1 correlation matrix.
#'
#' @return Object of class `tern_gee` as well as specific to the kind of regression
#'   which was used.
#' @export
#'
#' @examples
#' df <- fev_data
#' df$AVAL <- rbinom(n = nrow(df), size = 1, prob = 0.5)
#'
#' fit_gee(vars = vars_gee(arm = "ARMCD"), data = df)
#'
#' fit_gee(vars = vars_gee(arm = "ARMCD"), data = df, cor_struct = "compound symmetry")
fit_gee <- function(vars = vars_gee(),
                    data,
                    regression = c("logistic"),
                    cor_struct = c("unstructured", "toeplitz", "compound symmetry", "auto-regressive")) {
  formula <- build_formula(vars)

  regression <- match.arg(regression)
  family <- build_family(regression)

  data <- order_data(data, vars)
  data[[".id"]] <- data[[vars$id]]
  data[[".waves"]] <- as.integer(data[[vars$visit]])

  cor_struct <- match.arg(cor_struct)
  cor_details <- build_cor_details(cor_struct, vars, data)

  fit <- geeasy::geelm(
    formula = formula,
    id = .id,
    waves = .waves,
    data = data,
    family = family$object,
    corstr = cor_details$str,
    Mv = cor_details$mv,
    control = family$control
  )

  fit$qic <- geepack::QIC(fit)
  fit$visit_levels <- levels(data[[vars$visit]])
  fit$vars <- vars
  fit$data <- data
  assert_factor(data[[vars$arm]])
  fit$ref_level <- levels(data[[vars$arm]])[1L]

  structure(
    fit,
    class = c(family$class, "tern_gee", class(fit))
  )
}

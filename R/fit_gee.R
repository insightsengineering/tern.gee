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

control_gee <- function(tol = 0.001,
                        maxiter = 25,
                        silent = TRUE,
                        scale.fix = TRUE,
                        scale.value = 1) {
  list(
    tol = tol,
    maxiter = maxiter,
    silent = silent,
    scale.fix = scale.fix,
    scale.value = scale.value
  )
}

#' @keywords internal
build_formula <- function(vars) {
  assert_list(vars)
  covariates_part <- paste(
    vars$covariates,
    collapse = " + "
  )
  arm_part <- if (is.null(vars$arm)) NULL else vars$arm
  rhs_formula <- paste(
    c(arm_part, covariates_part),
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

  result_object <- switch(
    regression,
    logistic = stats::binomial(link = "logit"),
    stop(paste("regression type", regression, "not supported"))
  )

  result_class <- paste0("tern_gee_", regression)

  list(
    object = result_object,
    class = result_class
  )
}

#' @keywords internal
build_cor_details <- function(cor_str, vars, data) {
  assert_string(cor_str)
  assert_list(vars)
  assert_data_frame(data)

  result_str <- switch(
    cor_str,
    "unstructured" = "unstructured",
    "toeplitz" = "stat_M_dep",
    "compound symmetry" = "exchangeable",
    "auto-regressive" = "AR-M",
    stop(paste("correlation structure", cor_str, "not available"))
  )

  result_mv <- switch(
    cor_str,
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
#' @param control (`list`)\cr see [control_gee()].
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
fit_gee <- function(vars = vars_gee(),
                    data,
                    regression = c("logistic"),
                    cor_struct = c("unstructured", "toeplitz", "compound symmetry", "auto-regressive"),
                    control = control_gee()) {
  formula <- build_formula(vars)

  regression <- match.arg(regression)
  family <- build_family(regression)

  data <- order_data(data, vars)
  data[[".id"]] <- data[[vars$id]]

  cor_struct <- match.arg(cor_struct)
  cor_details <- build_cor_details(cor_struct, vars, data)

  capture.output(fit <- suppressMessages(gee::gee(
    formula = formula,
    id = .id,
    data = data,
    na.action = na.omit,  # That is the only option here.
    tol = control$tol,
    maxiter = control$maxiter,
    family = family$object,
    corstr = cor_details$str,
    Mv = cor_details$mv,
    silent = control$silent,
    scale.fix = control$scale.fix,
    scale.value = control$scale.value
  )))

  fit$visit_levels <- levels(data[[vars$visit]])
  fit$vars <- vars
  fit$data <- data
  fit$ref_level <- levels(data[[vars$arm]])[1L]

  structure(
    fit,
    class = c(family$class, "tern_gee", class(fit))
  )
}



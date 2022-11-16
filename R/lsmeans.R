#' Extract Least Square Means from a GEE Model
#'
#' @param object (`tern_gee`)\cr result of [fit_gee()].
#' @param conf_level (`proportion`)\cr confidence level
#' @param weights (`string`)\cr type of weights to be used for the least square means,
#'   see [emmeans::emmeans()] for details.
#' @param ... additional arguments for methods
#'
#' @return A `data.frame` with least-square means and contrasts. Additional
#'   classes allow to dispatch downstream methods correctly, too.
#' @export
#'
#' @examples
#' df <- fev_data
#' df$AVAL <- rbinom(n = nrow(df), size = 1, prob = 0.5)
#' fit <- fit_gee(vars = vars_gee(arm = "ARMCD"), data = df)
#'
#' lsmeans(fit)
#'
#' lsmeans(fit, conf_level = 0.90, weights = "equal")
lsmeans <- function(object,
                    conf_level = 0.95,
                    weights = "proportional",
                    ...) {
  UseMethod("lsmeans", object)
}

#' @rdname lsmeans
#' @exportS3Method
lsmeans.tern_gee_logistic <- function(object,
                                      conf_level = 0.95,
                                      weights = "proportional",
                                      ...) {
  specs <- as.formula(paste("~", object$vars$arm))
  prop_emm <- emmeans::emmeans(
    object = object,
    specs = specs,
    weights = weights,
    type = "response",
    data = object$data
  )

  prop_df <- cbind(
    as.data.frame(prop_emm)[, c(object$vars$arm, "prob", "SE", "asymp.LCL", "asymp.UCL")],
    n = as.list(prop_emm)$extras[, ".wgt."]
  )
  names(prop_df) <- c(object$vars$arm, "prop_est", "prop_est_se", "prop_lower_cl", "prop_upper_cl", "n")
  ref_level <- levels(object$data[[object$vars$arm]])[1L]

  or_emm <- stats::confint(
    graphics::pairs(prop_emm, reverse = TRUE),
    level = conf_level
  )
  or_df <- as.data.frame(or_emm)
  or_df$comparator <- gsub(pattern = ".+ / (.+)", replacement = "\\1", x = or_df$contrast)
  or_df[[object$vars$arm]] <- gsub(pattern = "(.+) / .+", replacement = "\\1", x = or_df$contrast)
  or_df <- or_df[or_df$comparator == ref_level, ]
  or_df <- rbind(NA, or_df)
  or_df[1L, object$vars$arm] <- ref_level
  or_df <- or_df[, c(object$vars$arm, "odds.ratio", "asymp.LCL", "asymp.UCL")]
  or_df <- cbind(or_df, log(or_df[, -1L]), conf_level)
  names(or_df) <- c(
    object$vars$arm,
    "or_est", "or_lower_cl", "or_upper_cl",
    "log_or_est", "log_or_lower_cl", "log_or_upper_cl",
    "conf_level"
  )

  result <- merge(prop_df, or_df, by = object$vars$arm)

  structure(
    result,
    class = c("lsmeans_logistic", class(result))
  )
}

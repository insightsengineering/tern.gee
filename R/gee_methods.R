#' Method for GEE Models
#'
#' Additional methods which can simplify working with the GEE result object.
#' @name gee_methods
NULL

#' @rdname gee_methods
#' @importFrom stats vcov
#' @exportS3Method
vcov.gee <- function(object, ...) {
  object$robust.variance
}

#' @rdname gee_methods
#' @importFrom nlme VarCorr
#' @exportS3Method
VarCorr.tern_gee <- function(x, sigma = x$scale, ...) {
  mat <- x$working.correlation * sigma^2
  rownames(mat) <- colnames(mat) <- x$visit_levels
  mat
}

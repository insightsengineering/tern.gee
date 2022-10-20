#' Method for GEE Models
#'
#' Additional methods which can simplify working with the GEE result object.
#' @name gee_methods
NULL

#' @rdname gee_methods
#' @importFrom nlme VarCorr
#' @exportS3Method
VarCorr.tern_gee <- function(x, sigma = x$scale, ...) {
  # todo - need to figure out how to build the matrix from
  # x$geese$alpha and the x$corstr etc - maybe just 4 different cases
  # and build the matrix each time.

  # mat <- x$working.correlation * sigma^2
  # rownames(mat) <- colnames(mat) <- x$visit_levels
  # mat
}

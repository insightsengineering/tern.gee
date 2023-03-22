#' `tern.gee` Package
#'
#' Create tables and graphs for GEE model fits.
#'
"_PACKAGE"

#' @import checkmate
#' @import rtables
#' @importFrom rtables add_colcounts
#' @importFrom stats acf as.formula
#' @importFrom tern f_conf_level
#' @importFrom emmeans emmeans
NULL

# to avoid NOTEs from R CMD CHECK
utils::globalVariables(c(
  ".id", ".waves"
))

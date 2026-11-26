# Setup ----

# Same preparation as in `fit_gee()`. The data contain missing responses.
geelm_data <- local({
  d <- as.data.frame(fev_data)
  d$.id <- as.integer(d$USUBJID)
  d$.waves <- as.integer(d$AVISIT)
  d[order(d$.id, d$.waves), ]
})
geelm_formula <- FEV1_BINARY ~ ARMCD + RACE
geelm_n_complete <- sum(stats::complete.cases(geelm_data[c("FEV1_BINARY", "ARMCD", "RACE")]))

# Subjects with complete data at all 4 visits.
geelm_ids_4 <- local({
  n_obs <- tapply(!is.na(geelm_data$FEV1_BINARY), geelm_data$.id, sum)
  as.integer(names(n_obs)[n_obs == 4])
})

fit_geelm <- function(corstr, mv = 1, data = geelm_data, control = geelm_control(scale.fix = TRUE),
                      formula = geelm_formula) {
  geelm(
    formula,
    id = .id, waves = .waves, data = data, family = stats::binomial(),
    corstr = corstr, Mv = mv, control = control
  )
}

# Small toy data: 3 clusters with sizes 2, 3, 3.
toy_len <- c(2, 3, 3)

# Builds the dense block diagonal matrix with one `block_fun(size)` block per cluster.
dense_block_diag <- function(len, block_fun) {
  n <- sum(len)
  out <- matrix(0, n, n)
  start <- cumsum(len) - len
  for (i in seq_along(len)) {
    idx <- start[i] + seq_len(len[i])
    out[idx, idx] <- block_fun(len[i])
  }
  out
}

# geelm_control ----

test_that("geelm_control returns the expected defaults", {
  result <- geelm_control()
  expect_list(result)
  expect_null(result$init.beta)
  expect_identical(result$init.phi, 1)
  expect_identical(result$tol, 0.00001)
  expect_identical(result$maxit, 20)
  expect_false(result$scale.fix)
  expect_identical(result$useP, 1)
  expect_identical(result$std.err, "san.se")
  expect_identical(result[c("jack", "j1s", "fij")], list(jack = 0, j1s = 0, fij = 0))
})

test_that("geelm_control converts useP to numeric", {
  expect_identical(geelm_control(useP = FALSE)$useP, 0)
})

test_that("geelm_control fails when scale is fixed without initial dispersion", {
  expect_error(
    geelm_control(scale.fix = TRUE, init.phi = NULL),
    "init.phi must be supplied"
  )
})

# Utilities ----

test_that("is_equidistant works as expected", {
  expect_true(is_equidistant(numeric(0)))
  expect_true(is_equidistant(5))
  expect_true(is_equidistant(c(1, 2, 3)))
  expect_true(is_equidistant(c(2, 4, 6, 8)))
  expect_false(is_equidistant(c(1, 2, 7)))
})

test_that("get_xlevels returns factor levels from a model frame", {
  mf <- stats::model.frame(geelm_formula, geelm_data)
  result <- get_xlevels(mf)
  expect_identical(names(result), c("ARMCD", "RACE"))
  expect_identical(result$ARMCD, levels(geelm_data$ARMCD))
  expect_identical(result$RACE, levels(geelm_data$RACE))
})

test_that("get_xlevels returns NULL when there are no factors", {
  mf <- stats::model.frame(FEV1_BINARY ~ FEV1, geelm_data)
  expect_null(get_xlevels(mf))
})

test_that("lookup_var_arg finds variables in data by name and by string", {
  data <- data.frame(a = 1:3, b = 4:6)
  wrapper <- function(arg) lookup_var_arg(substitute(arg), data, "x")
  expect_identical(wrapper(a), 1:3)
  expect_identical(wrapper("b"), 4:6)
})

test_that("lookup_var_arg fails for variables with wrong length", {
  data <- data.frame(a = 1:3)
  wrong <- 1:2 # nolint
  wrapper <- function(arg) lookup_var_arg(substitute(arg), data, "id")
  expect_error(wrapper(wrong), "Invalid id")
})

test_that("get_block_diag returns block diagonal matrix of ones with indices", {
  result <- get_block_diag(toy_len)
  expect_identical(names(result), c("BDiag", "row.vec", "col.vec"))
  expected <- dense_block_diag(toy_len, function(n) matrix(1, n, n))
  expect_equal(as.matrix(result$BDiag), expected, ignore_attr = TRUE)
  expect_length(result$row.vec, sum(toy_len^2))
  expect_length(result$col.vec, sum(toy_len^2))
})

test_that("get_block_diag works with a single cluster", {
  result <- get_block_diag(3)
  expect_equal(as.matrix(result$BDiag), matrix(1, 3, 3), ignore_attr = TRUE)
})

# Inverse correlation matrices ----

test_that("get_alpha_inv_ar returns the inverse AR1 correlation matrix", {
  alpha <- 0.4
  len <- c(1, toy_len)
  tmp <- build_alpha_inv_ar(len)
  result <- get_alpha_inv_ar(alpha, tmp$a1, tmp$a2, tmp$a3, tmp$a4, tmp$row.vec, tmp$col.vec)
  expected <- dense_block_diag(len, function(n) solve(alpha^abs(outer(seq_len(n), seq_len(n), "-"))))
  expect_equal(as.matrix(result), expected, ignore_attr = TRUE, tolerance = 1e-10)
})

test_that("get_alpha_inv_ex returns the inverse exchangeable correlation matrix", {
  alpha <- 0.3
  block_diag <- get_block_diag(toy_len)$BDiag
  n_vec <- rep(toy_len, toy_len)
  result <- get_alpha_inv_ex(alpha, n_vec, block_diag)
  expected <- dense_block_diag(toy_len, function(n) {
    m <- matrix(alpha, n, n)
    diag(m) <- 1
    solve(m)
  })
  expect_equal(as.matrix(result), expected, ignore_attr = TRUE, tolerance = 1e-10)
})

test_that("get_alpha_inv_mdep returns the inverse banded correlation matrix", {
  alpha <- c(0.3, 0.1)
  len <- c(1, toy_len, 4)
  tmp <- get_block_diag(len)
  result <- get_alpha_inv_mdep(alpha, len, tmp$row.vec, tmp$col.vec)
  expected <- dense_block_diag(len, function(n) {
    lag <- abs(outer(seq_len(n), seq_len(n), "-"))
    m <- ifelse(lag == 0, 1, ifelse(lag <= length(alpha), alpha[pmax(lag, 1)], 0))
    solve(m)
  })
  expect_equal(as.matrix(result), expected, ignore_attr = TRUE, tolerance = 1e-10)
})

test_that("get_alpha_inv_unstruc returns the inverse unstructured correlation matrix", {
  # Upper triangle in column-major order: (1,2), (1,3), (2,3).
  alpha <- c(0.2, 0.1, 0.3)
  tmp <- get_block_diag(toy_len)
  result <- get_alpha_inv_unstruc(alpha, toy_len, tmp$row.vec, tmp$col.vec)
  full <- diag(3)
  full[upper.tri(full)] <- alpha
  full[lower.tri(full)] <- t(full)[lower.tri(full)]
  expected <- dense_block_diag(toy_len, function(n) solve(full[seq_len(n), seq_len(n), drop = FALSE]))
  expect_equal(as.matrix(result), expected, ignore_attr = TRUE, tolerance = 1e-10)
})

# geelm results ----

test_that("geelm returns a geeglm compatible object", {
  result <- expect_silent(geelm(
    geelm_formula,
    id = .id, waves = .waves, data = geelm_data, family = stats::binomial(),
    corstr = "exchangeable", control = geelm_control(scale.fix = TRUE)
  ))
  expect_class(result, c("geelm", "geeglm", "gee", "glm", "lm"))
  expect_class(result$geese, "geese")
  expect_named(coef(result), c("(Intercept)", "ARMCDTRT", "RACEBlack or African American", "RACEWhite"))
  expect_identical(dim(vcov(result)), c(4L, 4L))
  expect_identical(result$corstr, "exchangeable")
  expect_identical(result$std.err, "san.se")
  expect_length(result$fitted.values, geelm_n_complete)
  expect_length(result$id, geelm_n_complete)
  expect_identical(result$xlevels$ARMCD, levels(geelm_data$ARMCD))
  # Partial matching happens inside the `geepack` methods.
  withr::with_options(opts_partial_match_old, {
    expect_data_frame(stats::coef(summary(result)), nrows = 4L)
  })
  # `QIC()` refits the stored call with independence correlation.
  expect_number(geepack::QIC(result)[["QIC"]])
})

test_that("geelm with independence matches glm and geepack", {
  result <- fit_geelm("independence")
  glm_fit <- stats::glm(geelm_formula, data = geelm_data, family = stats::binomial())
  expect_equal(coef(result), coef(glm_fit), tolerance = 1e-8)
  expect_identical(result$geese$alpha, 0)

  withr::with_options(opts_partial_match_old, {
    geeglm_fit <- geepack::geeglm(
      geelm_formula,
      id = .id, waves = .waves, data = geelm_data,
      family = stats::binomial(), corstr = "independence", scale.fix = TRUE
    )
    expect_equal(vcov(result), vcov(geeglm_fit), tolerance = 1e-8, ignore_attr = TRUE)
  })
})

test_that("geelm with exchangeable correlation is close to geepack", {
  result <- fit_geelm("exchangeable")
  geeglm_fit <- withr::with_options(opts_partial_match_old, {
    geepack::geeglm(
      geelm_formula,
      id = .id, waves = .waves, data = geelm_data,
      family = stats::binomial(), corstr = "exchangeable", scale.fix = TRUE
    )
  })
  # The correlation moment estimators differ slightly between the two packages.
  expect_equal(coef(result), coef(geeglm_fit), tolerance = 1e-3)
  expect_equal(result$geese$alpha, geeglm_fit$geese$alpha, tolerance = 0.05, ignore_attr = TRUE)
})

# Reference values below agree exactly with `geeasy::geelm()` version 0.1.3.

test_that("geelm gives the expected results for exchangeable correlation", {
  result <- fit_geelm("exchangeable")
  expect_equal(unname(coef(result)), c(1.7931615, 0.7132700, 0.2043683, 1.3772946), tolerance = 1e-6)
  expect_equal(unname(sqrt(diag(vcov(result)))), c(0.2769530, 0.3294433, 0.3238191, 0.5528630), tolerance = 1e-6)
  expect_equal(result$geese$alpha, -0.0431269, tolerance = 1e-5)
})

test_that("geelm gives the expected results for AR1 correlation", {
  result <- fit_geelm("ar1")
  expect_equal(unname(coef(result)), c(1.7880949, 0.7161427, 0.2149498, 1.3645613), tolerance = 1e-6)
  expect_equal(unname(sqrt(diag(vcov(result)))), c(0.2738198, 0.3294603, 0.3228504, 0.5518996), tolerance = 1e-6)
  expect_equal(result$geese$alpha, -0.0072977, tolerance = 1e-4)
})

test_that("geelm gives the expected results for m-dependent correlation", {
  result <- fit_geelm("m-dependent", mv = 2)
  expect_equal(unname(coef(result)), c(1.7972223, 0.6958603, 0.1873876, 1.3984448), tolerance = 1e-6)
  expect_equal(unname(sqrt(diag(vcov(result)))), c(0.2775508, 0.3296899, 0.3243606, 0.5533839), tolerance = 1e-6)
  expect_equal(result$geese$alpha, c(-0.0064816, -0.1118319), tolerance = 1e-5)
})

test_that("geelm with 1-dependent correlation is close to AR1", {
  # Same moment estimator for the lag-1 correlation, but a banded instead of AR1 working correlation.
  result <- fit_geelm("m-dependent", mv = 1)
  expected <- fit_geelm("ar1")
  expect_length(result$geese$alpha, 1L)
  expect_equal(coef(result), coef(expected), tolerance = 1e-4)
  expect_equal(result$geese$alpha, expected$geese$alpha, tolerance = 1e-3)
})

test_that("geelm gives the expected results for unstructured correlation", {
  result <- fit_geelm("unstructured")
  expect_equal(unname(coef(result)), c(1.7582943, 0.6784657, 0.1705619, 1.3864354), tolerance = 1e-6)
  expect_equal(unname(sqrt(diag(vcov(result)))), c(0.2786257, 0.3302633, 0.3256145, 0.5543606), tolerance = 1e-6)
  expect_equal(
    result$geese$alpha,
    c(-0.0564589, -0.1257370, 0.0678152, -0.0835993, -0.0577740, 0.0092168),
    tolerance = 1e-5
  )
})

test_that("geelm results do not depend on the row order of the input data", {
  expected <- fit_geelm("exchangeable")
  set.seed(123)
  perm <- sample(nrow(geelm_data))
  shuffled <- geelm_data[perm, ]
  result <- fit_geelm("exchangeable", data = shuffled)
  expect_equal(coef(result), coef(expected))
  expect_equal(vcov(result), vcov(expected))
  # Fitted values are returned in the order of the (complete) input data.
  key <- function(d) paste(d$.id, d$.waves)[!is.na(d$FEV1_BINARY)]
  reorder <- match(key(geelm_data), key(shuffled))
  expect_equal(unname(result$fitted.values[reorder]), unname(expected$fitted.values))
  expect_identical(result$id, shuffled$.id[!is.na(shuffled$FEV1_BINARY)])
})

test_that("geelm drops observations with missing values", {
  data <- geelm_data
  rows <- which(!is.na(data$FEV1_BINARY))[c(2, 5, 10)]
  data$FEV1_BINARY[rows[1:2]] <- NA
  data$RACE[rows[3]] <- NA
  result <- fit_geelm("exchangeable", data = data)
  # Removing the rows creates gaps in the waves, hence the warning.
  expected <- suppressWarnings(fit_geelm("exchangeable", data = data[-rows, ]))
  expect_length(result$fitted.values, geelm_n_complete - 3L)
  expect_length(result$prior.weights, geelm_n_complete - 3L)
  expect_equal(coef(result), coef(expected))
  expect_equal(unname(result$fitted.values), unname(expected$fitted.values))
})

test_that("summary works for geelm fits with dropped observations", {
  data <- geelm_data
  result <- fit_geelm("exchangeable", data = data)
  expected <- suppressWarnings(fit_geelm("exchangeable", data = data[!is.na(data$FEV1_BINARY), ]))
  expect_length(result$prior.weights, geelm_n_complete)
  withr::with_options(opts_partial_match_old, {
    expect_equal(stats::coef(summary(result)), stats::coef(summary(expected)))
  })
})

test_that("geelm estimates the dispersion when the scale is not fixed", {
  result <- fit_geelm("exchangeable", control = geelm_control())
  fixed <- fit_geelm("exchangeable")
  expect_false(result$geese$model$scale.fix)
  expect_true(result$geese$gamma != 1)
  expect_identical(fixed$geese$gamma, 1)
})

test_that("geelm converges to the same estimates from given initial values", {
  expected <- fit_geelm("exchangeable")
  init <- coef(expected) + 0.1
  result <- fit_geelm("exchangeable", control = geelm_control(scale.fix = TRUE, init.beta = init))
  expect_equal(coef(result), coef(expected), tolerance = 1e-5)
})

test_that("geelm without n-p correction gives a smaller correlation estimate in absolute value", {
  result <- fit_geelm("exchangeable", control = geelm_control(scale.fix = TRUE, useP = FALSE))
  expected <- fit_geelm("exchangeable")
  # The correction only changes the denominator of the moment estimator.
  expect_lt(abs(result$geese$alpha), abs(expected$geese$alpha))
  expect_equal(coef(result), coef(expected), tolerance = 1e-3)
})

test_that("geelm works with a single cluster", {
  data <- geelm_data[geelm_data$.id == geelm_ids_4[1], ]
  data$FEV1_BINARY <- c(0L, 1L, 1L, 0L)
  result <- geelm(
    FEV1_BINARY ~ 1,
    id = .id, waves = .waves, data = data, family = stats::binomial(),
    corstr = "independence", control = geelm_control(scale.fix = TRUE)
  )
  expect_equal(unname(coef(result)), 0, tolerance = 1e-8)
})

test_that("geelm warns for non-equidistant waves", {
  data <- geelm_data
  data$.waves[data$.waves == 4L] <- 10L
  expect_warning(
    result <- fit_geelm("exchangeable", data = data),
    "Non-equidistant waves"
  )
  # Only the ordering of the waves is used.
  expect_equal(coef(result), coef(fit_geelm("exchangeable")))
})

test_that("geelm fails for invalid inputs", {
  expect_error(fit_geelm("toeplitz"), "should be one of")
  expect_error(fit_geelm("m-dependent", mv = 1.5), "Mv must be an integer")
  expect_error(fit_geelm("m-dependent", mv = 4), "Mv >=  max\\(clustersize\\)")
  expect_error(
    geelm(geelm_formula, id = .id, waves = .waves, data = geelm_data, family = "binomial"),
    "family must be a family object"
  )
  data <- geelm_data
  data$.waves <- as.character(data$.waves)
  expect_error(fit_geelm("exchangeable", data = data), "waves must be numeric")
})

test_that("geelm fails for unstructured correlation with too few subjects", {
  # 6 correlation parameters but only 5 subjects.
  data <- geelm_data[geelm_data$.id %in% geelm_ids_4[1:5], ]
  expect_error(fit_geelm("unstructured", data = data), "not enough subjects")
})

test_that("geelm fails for unstructured correlation with too few complete clusters", {
  # Only 2 subjects (not more than 2 coefficients) have the largest cluster size.
  data <- geelm_data[geelm_data$.id %in% geelm_ids_4[1:20], ]
  data <- data[data$.waves <= 3L | data$.id %in% geelm_ids_4[1:2], ]
  expect_error(
    fit_geelm("unstructured", data = data, formula = FEV1_BINARY ~ ARMCD),
    "Number of clusters of largest size is less than p"
  )
})

# geelm_fit ----

test_that("geelm_fit fails when the link of the mean response is not finite", {
  x <- matrix(1, nrow = 4, dimnames = list(NULL, "(Intercept)"))
  expect_error(
    geelm_fit(
      x = x, y = rep(0, 4), id = c(1, 1, 2, 2), offset = rep(0, 4),
      family = stats::binomial(), weights = rep(1, 4),
      control = geelm_control(scale.fix = TRUE), corstr = "independence"
    ),
    "Infinite or NaN in the link"
  )
})

test_that("geelm_fit fails when the variance of the mean response is not finite", {
  family <- stats::poisson()
  family$variance <- function(mu) rep(Inf, length(mu))
  x <- matrix(1, nrow = 4, dimnames = list(NULL, "(Intercept)"))
  expect_error(
    geelm_fit(
      x = x, y = c(1, 2, 3, 4), id = c(1, 1, 2, 2), offset = rep(0, 4),
      family = family, weights = rep(1, 4),
      control = geelm_control(scale.fix = TRUE), corstr = "independence"
    ),
    "Infinite or NaN in the variance"
  )
})

test_that("geelm_fit fails for unsupported correlation structures", {
  x <- matrix(1, nrow = 4, dimnames = list(NULL, "(Intercept)"))
  expect_error(
    geelm_fit(
      x = x, y = c(0, 1, 1, 0), id = c(1, 1, 2, 2), offset = rep(0, 4),
      family = stats::binomial(), weights = rep(1, 4),
      control = geelm_control(scale.fix = TRUE), corstr = "fixed"
    ),
    "Unsupported correlation structure"
  )
})

test_that("geelm_fit warns when the algorithm does not converge", {
  expect_warning(
    fit_geelm("exchangeable", control = geelm_control(scale.fix = TRUE, maxit = 1)),
    "Did not converge"
  )
})

test_that("geelm_fit warns when few clusters inform the m-dependent correlations", {
  # Only 2 subjects (not more than 2 coefficients) have more than Mv = 2 observations.
  data <- geelm_data[geelm_data$.id %in% geelm_ids_4[1:30], ]
  data <- data[data$.waves <= 2L | data$.id %in% geelm_ids_4[1:2], ]
  expect_warning(
    fit_geelm("m-dependent", mv = 2, data = data, formula = FEV1_BINARY ~ ARMCD),
    "very low sample size"
  )
})

test_that("geelm_fit can skip the sandwich estimator", {
  d <- geelm_data[!is.na(geelm_data$FEV1_BINARY), ]
  x <- stats::model.matrix(geelm_formula, d)
  y <- d$FEV1_BINARY
  result <- geelm_fit(
    x = x, y = y, id = d$.id, offset = rep(0, nrow(d)),
    family = stats::binomial(), weights = rep(1, nrow(d)),
    control = geelm_control(scale.fix = TRUE, std.err = "naive"), corstr = "exchangeable"
  )
  expect_class(result, "geelm_fit")
  expect_identical(result$vbeta, as.matrix("no sandwich"))
  expect_identical(dim(as.matrix(result$naiv.var)), c(4L, 4L))
  sandwich <- fit_geelm("exchangeable")
  expect_equal(unname(result$beta), unname(coef(sandwich)))
})

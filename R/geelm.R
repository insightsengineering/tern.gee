# GEE fitting engine.
#
# The code in this file is adapted from the 'geeasy' package (version 0.1.3,
# <https://github.com/annennenne/geeasy>, GPL-3) by Anne Helby Petersen,
# Lee McDaniel and Søren Højsgaard, which in turn builds on the 'geeM' package
# (GPL-3) by Lee McDaniel and Nick Henderson. Only the parts needed by
# `fit_gee()` were retained: the "geeasy" engine with "geelm" output, and the
# "exchangeable", "ar1", "m-dependent" and "unstructured" correlation
# structures (plus "independence", which `geepack::QIC()` uses to refit the
# model). Variable names follow the upstream code to ease comparison.
#
# nolint start

#' Control Settings for GEE Estimation
#'
#' Settings for controlling technical details of the GEE fitting in [geelm()].
#'
#' @param init.beta (`numeric` or `NULL`)\cr initial values for the mean
#'   structure parameters. If `NULL`, these are obtained from a GLM fit.
#' @param init.phi (`number`)\cr initial value of the dispersion parameter.
#' @param tol (`number`)\cr tolerance for asserting convergence.
#' @param maxit (`count`)\cr maximum number of iterations.
#' @param scale.fix (`flag`)\cr whether the dispersion parameter should be fixed
#'   at `init.phi`.
#' @param useP (`flag`)\cr whether to use the n-p correction for the dispersion
#'   and correlation estimates.
#' @param std.err (`string`)\cr standard error estimation method, either
#'   `"san.se"` (sandwich) or `"naive"`.
#'
#' @return A list of values used for controlling model fitting.
#' @keywords internal
geelm_control <- function(init.beta = NULL, init.phi = 1,
                          tol = 0.00001, maxit = 20, scale.fix = FALSE,
                          useP = TRUE, std.err = "san.se") {
  if (scale.fix && is.null(init.phi)) {
    stop("If scale.fix = TRUE, then init.phi must be supplied")
  }
  list(
    init.beta = init.beta,
    init.phi = init.phi,
    tol = tol,
    maxit = maxit,
    scale.fix = scale.fix,
    useP = as.numeric(useP),
    jack = 0, # for geese methods
    j1s = 0, # for geese methods
    fij = 0, # for geese methods
    std.err = std.err
  )
}

#' Fit a GEE Model with the `geelm` Engine
#'
#' Estimates mean structure parameters and their sandwich standard errors for
#' generalized linear models with correlated observations. The returned object
#' has class `geelm` and is compatible with the `geeglm` methods from `geepack`
#' (e.g. `summary()`, `QIC()`) as well as with `emmeans`.
#'
#' @param formula (`formula`)\cr model formula, possibly including an offset.
#' @param id (`name`)\cr variable in `data` identifying the clusters.
#' @param waves (`name`)\cr numeric variable in `data` giving the time ordering
#'   within clusters. Only the ordering is used.
#' @param data (`data.frame`)\cr input data.
#' @param family (`family`)\cr error distribution and link function.
#' @param corstr (`string`)\cr correlation structure, one of `"independence"`,
#'   `"exchangeable"`, `"ar1"`, `"m-dependent"` or `"unstructured"`.
#' @param Mv (`count`)\cr order of the `"m-dependent"` structure.
#' @param control (`list`)\cr see [geelm_control()].
#'
#' @return Object of class `geelm` (inheriting from `geeglm`, `gee`, `glm`, `lm`).
#' @keywords internal
geelm <- function(formula, id, waves, data,
                  family, corstr = "exchangeable", Mv = 1,
                  control = geelm_control()) {
  thiscall <- match.call()

  corstr <- match.arg(corstr, c("independence", "exchangeable", "ar1", "m-dependent", "unstructured"))
  if (corstr == "m-dependent") {
    if (!is.numeric(Mv) || !(length(Mv) == 1) || round(Mv, 0) != Mv || Mv < 0) {
      stop("Mv must be an integer")
    }
    attr(corstr, "Mv") <- Mv
  }

  if (!inherits(family, "family")) {
    stop("family must be a family object")
  }
  famret <- family

  # Data and variables.
  dat <- stats::model.frame(formula, data, na.action = stats::na.pass)
  nn <- dim(dat)[1]

  dat$id <- lookup_var_arg(thiscall$id, data, "id")
  dat$weights <- rep(1, nn)
  dat$waves <- lookup_var_arg(thiscall$waves, data, "waves")
  if (!is.numeric(dat$waves)) stop("waves must be numeric")

  formulaoffset <- stats::model.offset(dat)
  if (is.null(formulaoffset)) formulaoffset <- rep(0, nn)
  dat$offset <- formulaoffset

  # Sort data by id and waves.
  neworder <- order(dat$id, dat$waves)
  dat <- dat[neworder, ]

  # Only the ordering of the waves is used.
  waves_are_equidist <- by(dat$waves, as.factor(dat$id), is_equidistant)
  if (any(!waves_are_equidist)) {
    warning(paste(
      "Non-equidistant waves were provided.",
      "Note that only their ordering was used for model fitting.",
      "Their numeric values were ignored."
    ))
  }
  dat$waves <- NULL

  # Missing values.
  dropind <- which(!stats::complete.cases(dat))
  dat <- stats::na.omit(dat)

  X <- stats::model.matrix(formula, dat)
  Y <- stats::model.response(dat)

  results <- geelm_fit(
    x = X, y = Y, offset = dat$offset, weights = dat$weights,
    control = control, id = dat$id, family = famret,
    corstr = corstr
  )

  # Pack output into a geeglm-compatible object.
  coefs <- results$beta
  names(coefs) <- colnames(X)

  model_rank <- Matrix::rankMatrix(stats::na.omit(X))

  modelInfo <- list(
    mean.link = famret$link,
    variance = famret$family,
    sca.link = "identity",
    cor.link = "identity",
    corstr = corstr,
    scale.fix = control$scale.fix
  )

  # Alternative variance estimates are not supported: zero placeholders as in geepack.
  vbeta <- results$vbeta
  vbeta_otherse <- vbeta
  vbeta_otherse[, ] <- 0
  vgamma_otherse <- matrix(0, nrow = length(results$phi), ncol = length(results$phi))
  valpha_otherse <- matrix(0, nrow = length(results$alpha), ncol = length(results$alpha))

  geeseobj <- list(
    beta = coefs,
    vbeta = vbeta,
    vbeta.j1s = vbeta_otherse,
    vbeta.fij = vbeta_otherse,
    vbeta.ajs = vbeta_otherse,
    vbeta.naiv = as.matrix(results$naiv.var),
    gamma = results$phi,
    vgamma = vgamma_otherse,
    vgamma.j1s = vgamma_otherse,
    vgamma.fij = vgamma_otherse,
    vgamma.ajs = vgamma_otherse,
    alpha = results$alpha,
    valpha = valpha_otherse,
    valpha.j1s = valpha_otherse,
    valpha.fij = valpha_otherse,
    valpha.ajs = valpha_otherse,
    model = modelInfo,
    control = control,
    error = NA,
    clusz = results$clusz,
    zsca.names = NULL,
    zcor.names = NULL,
    xnames = colnames(X)
  )
  class(geeseobj) <- c("geese", "list")

  # Restore the input order, leaving out dropped observations.
  if (length(dropind) > 0) {
    oldorder_noNA <- order(neworder[-dropind])
  } else {
    oldorder_noNA <- order(neworder)
  }

  out <- list(
    coefficients = coefs,
    residuals = results$resid[oldorder_noNA],
    fitted.values = results$fitted.values[oldorder_noNA],
    rank = model_rank,
    qr = qr(X),
    family = famret,
    linear.predictors = results$eta[oldorder_noNA],
    weights = results$weights[oldorder_noNA],
    prior.weights = dat$weights[oldorder_noNA],
    df.residual = sum(results$weights != 0) - model_rank,
    y = Y[oldorder_noNA],
    model = dat[oldorder_noNA, ],
    call = thiscall,
    formula = formula,
    terms = stats::terms(formula),
    data = data,
    offset = results$offset[oldorder_noNA],
    control = control,
    method = "geelm_fit",
    constrasts = attr(X, "contrasts"),
    xlevels = get_xlevels(dat),
    geese = geeseobj,
    modelInfo = modelInfo,
    id = dat$id[oldorder_noNA],
    corstr = corstr,
    cor.link = "identity",
    std.err = control$std.err
  )
  class(out) <- c("geelm", "geeglm", "gee", "glm", "lm")
  out
}

#' Fisher Scoring Algorithm for GEE Models
#'
#' @param x (`matrix`)\cr design matrix, sorted by cluster and time.
#' @param y (`numeric`)\cr response.
#' @param id (`vector`)\cr cluster identifiers.
#' @param offset (`numeric`)\cr offset.
#' @param family (`family`)\cr family object.
#' @param weights (`numeric`)\cr observation weights.
#' @param control (`list`)\cr see [geelm_control()].
#' @param corstr (`string`)\cr correlation structure, see [geelm()].
#'
#' @return A list with the estimation results.
#' @keywords internal
geelm_fit <- function(x, y, id, offset, family, weights, control, corstr) {
  LinkFun <- family$linkfun
  InvLink <- family$linkinv
  VarFun <- family$variance
  InvLinkDeriv <- family$mu.eta

  p <- ncol(x)
  nn <- nrow(x)

  # Basic check that link and variance functions make sense.
  meanY <- mean(y)
  linkOfMean <- LinkFun(meanY) - mean(offset)
  if (!is.finite(linkOfMean)) {
    stop(paste(
      "Infinite or NaN in the link of the mean of responses.",
      "Make sure link function makes sense for these data."
    ))
  }
  if (!is.finite(VarFun(meanY))) {
    stop(paste(
      "Infinite or NaN in the variance of the mean of responses.",
      "Make sure variance function makes sense for these data."
    ))
  }

  sandwich <- control$std.err == "san.se"
  allobs <- TRUE

  # Initialization.
  beta <- control$init.beta
  if (is.null(beta)) {
    m_glm <- stats::glm.fit(x = x, y = y, offset = offset, family = family, weights = weights)
    beta <- m_glm$coefficients
  }
  phi <- control$init.phi
  maxit <- control$maxit
  scale.fix <- control$scale.fix
  useP <- control$useP
  tol <- control$tol

  uniqueid <- unique(id)
  K <- length(uniqueid)

  includedvec <- weights > 0
  includedlen <- as.numeric(summary(split(y, ifelse(!includedvec, NA, id), drop = TRUE))[, 1])
  len <- as.numeric(summary(split(y, id, drop = TRUE))[, 1])

  W <- Diagonal(x = weights)
  sqrtW <- sqrt(W)
  included <- Diagonal(x = as.numeric(includedvec))

  StdErr <- Diagonal(nn)
  dInvLinkdEta <- Diagonal(nn)
  Resid <- Diagonal(nn)

  # Initialization according to the correlation structure.
  if (corstr == "independence") {
    R.alpha.inv <- Diagonal(x = rep.int(1, nn)) / phi
    BlockDiag <- get_block_diag(len)$BDiag
  } else if (corstr == "ar1") {
    tmp <- build_alpha_inv_ar(len)
    a1 <- tmp$a1
    a2 <- tmp$a2
    a3 <- tmp$a3
    a4 <- tmp$a4
    row.vec <- tmp$row.vec
    col.vec <- tmp$col.vec
    BlockDiag <- get_block_diag(len)$BDiag
  } else if (corstr == "exchangeable") {
    tmp <- get_block_diag(len)
    BlockDiag <- tmp$BDiag
    n.vec <- vector("numeric", nn)
    index <- c(cumsum(len) - len, nn)
    for (i in 1:K) {
      n.vec[(index[i] + 1):index[i + 1]] <- rep(includedlen[i], len[i])
    }
  } else if (corstr == "m-dependent") {
    Mv <- attr(corstr, "Mv")
    if (Mv >= max(len)) {
      stop("Cannot estimate that many parameters: Mv >=  max(clustersize)")
    }
    tmp <- get_block_diag(len)
    BlockDiag <- tmp$BDiag
    row.vec <- tmp$row.vec
    col.vec <- tmp$col.vec
  } else if (corstr == "unstructured") {
    if (max(len^2 - len) / 2 > length(len)) {
      stop("Cannot estimate that many parameters: not enough subjects for unstructured correlation")
    }
    tmp <- get_block_diag(len)
    BlockDiag <- tmp$BDiag
    row.vec <- tmp$row.vec
    col.vec <- tmp$col.vec
  } else {
    stop("Unsupported correlation structure")
  }

  # Fisher scoring loop.
  done <- FALSE
  converged <- FALSE
  count <- 1
  beta.old <- beta
  unstable <- FALSE

  while (!done && count <= maxit) {
    eta <- as.vector(x %*% beta) + offset
    mu <- InvLink(eta)
    diag(StdErr) <- sqrt(1 / VarFun(mu))

    if (!scale.fix) {
      phi <- update_phi(y, mu, VarFun, p, StdErr, included, includedlen, sqrtW, useP)
    }

    Resid <- residuals_geelm(StdErr = StdErr, included = included, sqrtW = sqrtW, YY = y, mu = mu)

    if (corstr == "ar1") {
      alpha.new <- update_alpha_ar(
        y, mu, VarFun, phi, id, len, StdErr, Resid, p,
        included, includedlen, includedvec, allobs,
        sqrtW, BlockDiag, useP
      )
      R.alpha.inv <- get_alpha_inv_ar(alpha.new, a1, a2, a3, a4, row.vec, col.vec) / phi
    } else if (corstr == "exchangeable") {
      alpha.new <- update_alpha_ex(
        y, mu, VarFun, phi, id, len, StdErr,
        Resid, p, BlockDiag, included,
        includedlen, sqrtW, useP
      )
      R.alpha.inv <- get_alpha_inv_ex(alpha.new, n.vec, BlockDiag) / phi
    } else if (corstr == "m-dependent") {
      if (Mv == 1) {
        alpha.new <- update_alpha_ar(
          y, mu, VarFun, phi, id, len, StdErr, Resid, p,
          included, includedlen, includedvec, allobs,
          sqrtW, BlockDiag, useP
        )
      } else {
        alpha.new <- update_alpha_mdep(
          y, mu, VarFun, phi, id, len,
          StdErr, Resid, p, BlockDiag, Mv,
          included, includedlen,
          allobs, sqrtW, useP
        )
        if (sum(len > Mv) <= p) {
          unstable <- TRUE
        }
      }
      if (any(alpha.new >= 1)) {
        done <- TRUE
        warning("An estimated correlation great than 1 was found, stopping before convergence.")
      }
      R.alpha.inv <- get_alpha_inv_mdep(alpha.new, len, row.vec, col.vec) / phi
    } else if (corstr == "unstructured") {
      alpha.new <- update_alpha_unstruc(
        y, mu, VarFun, phi, id, len,
        StdErr, Resid, p, BlockDiag,
        included, includedlen, allobs,
        sqrtW, useP
      )
      if (any(alpha.new >= 1)) {
        done <- TRUE
        warning("An estimated correlation great than 1 was found, stopping before convergence.")
      }
      R.alpha.inv <- get_alpha_inv_unstruc(alpha.new, len, row.vec, col.vec) / phi
    } else if (corstr == "independence") {
      R.alpha.inv <- Diagonal(x = rep.int(1 / phi, nn))
      alpha.new <- "independent"
    }

    beta.list <- update_beta(
      y, x, beta, offset, InvLinkDeriv, InvLink, VarFun, R.alpha.inv, StdErr,
      dInvLinkdEta, tol, W, included
    )
    beta <- beta.list$beta

    if (max(abs((beta - beta.old) / (beta.old + .Machine$double.eps))) < tol) {
      converged <- TRUE
      done <- TRUE
    }
    beta.old <- beta
    count <- count + 1
  }

  biggest <- which.max(len)[1]
  index <- sum(len[1:biggest]) - len[biggest]
  if (K == 1) {
    biggest.R.alpha <- solve(R.alpha.inv)
  } else {
    biggest.R.alpha.inv <- R.alpha.inv[(index + 1):(index + len[biggest]), (index + 1):(index + len[biggest])]
    biggest.R.alpha <- solve(biggest.R.alpha.inv)
  }

  eta <- as.vector(x %*% beta) + offset
  if (sandwich) {
    sandvar.list <- get_sandwich(
      y, x, eta, id, R.alpha.inv, phi, InvLinkDeriv, InvLink, VarFun,
      beta.list$hess, StdErr, dInvLinkdEta, BlockDiag, W, included
    )
  } else {
    sandvar.list <- list(sandvar = "no sandwich")
  }

  alpha <- alpha.new
  if (is.character(alpha)) {
    alpha <- 0
  }

  pearson_resid <- (y - mu) * diag(sqrtW) / VarFun(mu)
  fitted.values <- InvLink(eta)

  if (!converged) {
    warning("Did not converge")
  }
  if (unstable) {
    warning(paste(
      "Number of subjects with number of observations >= Mv is very small,",
      "some correlations are estimated with very low sample size."
    ))
  }

  beta <- as.vector(beta)
  names(beta) <- colnames(x)

  out <- list(
    alpha = alpha,
    beta = beta,
    phi = phi,
    niter = count - 1,
    naiv.var = solve(beta.list$hess),
    corr = corstr,
    clusz = len,
    FunList = family,
    offset = offset,
    eta = eta,
    weights = weights,
    biggest.R.alpha = biggest.R.alpha / phi,
    resid = pearson_resid,
    fitted.values = fitted.values,
    vbeta = as.matrix(sandvar.list$sandvar)
  )
  class(out) <- c("geelm_fit", "list")
  out
}

# Utilities ----

# Find variable names or expressions in data or the calling environment of `geelm()`.
lookup_var_arg <- function(arg, data, name = NULL) {
  out <- eval(arg, envir = data, enclos = parent.frame(n = 2))
  if (length(out) == 1) {
    out <- get(arg, envir = as.environment(data))
  }
  if (length(out) != nrow(data)) {
    stop(paste("Invalid", ifelse(is.null(name), "argument", name)))
  }
  out
}

# Get levels for all factors from a model frame.
get_xlevels <- function(modelframe) {
  classes <- attr(stats::terms(modelframe), "dataClasses")
  factors <- names(classes[classes == "factor"])
  nfactors <- length(factors)
  if (nfactors > 0) {
    xlevels <- as.list(1:nfactors)
    for (i in 1:nfactors) {
      xlevels[[i]] <- levels(modelframe[, factors[i]])
    }
    names(xlevels) <- factors
    return(xlevels)
  }
  NULL
}

# Check whether a sorted numeric vector is equidistant.
is_equidistant <- function(x) {
  nx <- length(x)
  if (nx > 1) {
    length(unique(x[-1] - x[-nx])) == 1
  } else {
    TRUE
  }
}

# Pearson-type residual matrix.
residuals_geelm <- function(StdErr, included, sqrtW, YY, mu) {
  StdErr %*% included %*% sqrtW %*% Diagonal(x = YY - mu)
}

# Simple moment estimator of the dispersion parameter.
update_phi <- function(YY, mu, VarFun, p, StdErr, included, includedlen, sqrtW, useP) {
  resid <- diag(StdErr %*% included %*% sqrtW %*% Diagonal(x = YY - mu))
  phi <- (1 / (sum(included) - useP * p)) * crossprod(resid, resid)
  as.numeric(phi)
}

# Update the coefficients (10 Newton steps given the current working correlation).
update_beta <- function(YY, XX, beta, offset, InvLinkDeriv, InvLink,
                        VarFun, R.alpha.inv, StdErr, dInvLinkdEta, tol, W, included) {
  beta.new <- beta
  for (i in 1:10) {
    eta <- as.vector(XX %*% beta.new) + offset
    diag(dInvLinkdEta) <- InvLinkDeriv(eta)
    mu <- InvLink(eta)
    diag(StdErr) <- sqrt(1 / VarFun(mu))

    hess <- crossprod(
      StdErr %*% dInvLinkdEta %*% XX,
      R.alpha.inv %*% W %*% StdErr %*% dInvLinkdEta %*% XX
    )
    esteq <- crossprod(
      StdErr %*% dInvLinkdEta %*% XX,
      R.alpha.inv %*% W %*% StdErr %*% as.matrix(YY - mu)
    )
    update <- solve(hess, esteq)
    beta.new <- beta.new + as.vector(update)
  }
  list(beta = beta.new, hess = hess)
}

# Sandwich variance estimator.
get_sandwich <- function(YY, XX, eta, id, R.alpha.inv, phi, InvLinkDeriv,
                         InvLink, VarFun, hessMat, StdErr, dInvLinkdEta,
                         BlockDiag, W, included) {
  diag(dInvLinkdEta) <- InvLinkDeriv(eta)
  mu <- InvLink(eta)
  diag(StdErr) <- sqrt(1 / VarFun(mu))
  scoreDiag <- Diagonal(x = YY - mu)
  BlockDiag <- scoreDiag %*% BlockDiag %*% scoreDiag

  numsand <- as.matrix(crossprod(
    StdErr %*% dInvLinkdEta %*% XX,
    R.alpha.inv %*% W %*% StdErr %*%
      BlockDiag %*% StdErr %*% W %*%
      R.alpha.inv %*% StdErr %*%
      dInvLinkdEta %*% XX
  ))

  sandvar <- t(solve(hessMat, numsand))
  sandvar <- t(solve(t(hessMat), sandvar))
  list(sandvar = sandvar, numsand = numsand)
}

# Block diagonal matrix of ones with one block per cluster.
get_block_diag <- function(len) {
  K <- length(len)
  xvec <- rep.int(1, sum(len^2))
  row.vec <- col.vec <- vector("numeric", sum(len^2))
  add.vec <- cumsum(len) - len
  if (K == 1) {
    index <- c(0, sum(len^2))
  } else {
    index <- c(0, (cumsum(len^2) - len^2)[2:K], sum(len^2))
  }
  for (i in 1:K) {
    row.vec[(index[i] + 1):(index[i + 1])] <- rep.int((1:len[i]) + add.vec[i], len[i])
    col.vec[(index[i] + 1):(index[i + 1])] <- rep((1:len[i]) + add.vec[i], each = len[i])
  }
  BlockDiag <- sparseMatrix(i = row.vec, j = col.vec, x = xvec)
  list(BDiag = symmpart(BlockDiag), row.vec = row.vec, col.vec = col.vec)
}

# Correlation parameter updates ----

# Exchangeable correlation.
update_alpha_ex <- function(YY, mu, VarFun, phi, id, len, StdErr,
                            Resid, p, BlockDiag, included,
                            includedlen, sqrtW, useP) {
  W <- sqrtW^2
  denom <- phi * (sum(includedlen * (includedlen - 1)) / 2 - useP * p)
  BlockDiag <- StdErr %*% Diagonal(x = YY - mu) %*% included %*% BlockDiag %*% W %*%
    Diagonal(x = YY - mu) %*% StdErr
  alpha <- sum(triu(BlockDiag, k = 1))
  alpha / denom
}

# M-dependent correlation.
update_alpha_mdep <- function(YY, mu, VarFun, phi, id, len,
                              StdErr, Resid, p, BlockDiag, m,
                              included, includedlen, allobs, sqrtW, useP) {
  BlockDiag <- Resid %*% BlockDiag %*% Resid
  alpha.new <- vector("numeric", m)
  for (i in 1:m) {
    bandmat <- drop0(band(BlockDiag, i, i))
    # If there are few observations for a parameter, don't subtract p to avoid NaN.
    use_p_i <- if (sum(includedlen > i) > p) useP else 0
    if (allobs) {
      alpha.new[i] <- sum(bandmat) / (phi * (sum(as.numeric(len > i) * (len - i)) - use_p_i * p))
    } else {
      alpha.new[i] <- sum(bandmat) / (phi * (length(bandmat@i) - use_p_i * p))
    }
  }
  alpha.new
}

# AR-1 correlation, also used for 1-dependent.
update_alpha_ar <- function(YY, mu, VarFun, phi, id, len, StdErr, Resid, p,
                            included, includedlen, includedvec, allobs,
                            sqrtW, BlockDiag, useP) {
  Resid <- StdErr %*% included %*% sqrtW %*% Diagonal(x = YY - mu)
  denom <- phi * (sum(band(triu(included %*% BlockDiag %*% included, k = 1), k1 = 1, k2 = 1)) - useP * p)
  num <- sum(band(triu(Resid %*% BlockDiag %*% Resid, k = 1), k1 = 1, k2 = 1))
  as.numeric(num / denom)
}

# Unstructured correlation.
update_alpha_unstruc <- function(YY, mu, VarFun, phi, id, len, StdErr, Resid,
                                 p, BlockDiag, included, includedlen,
                                 allobs, sqrtW, useP) {
  ml <- max(len)
  BlockDiag <- Resid %*% BlockDiag %*% Resid
  alpha.new <- vector("numeric", sum(1:(ml - 1)))
  lalph <- length(alpha.new)

  row.vec <- NULL
  col.vec <- NULL
  for (i in 2:ml) {
    row.vec <- c(row.vec, 1:(i - 1))
    col.vec <- c(col.vec, rep(i, each = i - 1))
  }
  index <- cumsum(len) - len
  if (sum(includedlen == max(len)) <= p) {
    stop("Number of clusters of largest size is less than p.")
  }
  for (i in 1:lalph) {
    newrow <- index[which(len >= col.vec[i])] + row.vec[i]
    newcol <- index[which(len >= col.vec[i])] + col.vec[i]
    bdtmp <- BlockDiag[cbind(newrow, newcol)]
    if (allobs) {
      denom <- phi * (length(newrow) - useP * p)
    } else {
      denom <- phi * (sum(bdtmp != 0) - useP * p)
    }
    alpha.new[i] <- sum(bdtmp) / denom
  }
  alpha.new
}

# Inverse correlation matrices ----

# AR-1 inverse.
get_alpha_inv_ar <- function(alpha.new, a1, a2, a3, a4, row.vec, col.vec) {
  corr.vec <- c(
    alpha.new * a1 / (1 - alpha.new^2),
    ((1 + alpha.new^2) * a2 + a3) / (1 - alpha.new^2) + a4,
    alpha.new * a1 / (1 - alpha.new^2)
  )
  methods::as(sparseMatrix(i = row.vec, j = col.vec, x = corr.vec), "symmetricMatrix")
}

# Index structures for the AR-1 inverse.
build_alpha_inv_ar <- function(len) {
  nn <- sum(len)
  K <- length(len)
  a1 <- a2 <- a3 <- a4 <- vector("numeric", nn)
  index <- c(cumsum(len) - len, nn)

  for (i in 1:K) {
    if (len[i] > 1) {
      a1[(index[i] + 1):index[i + 1]] <- c(rep(-1, times = len[i] - 1), 0)
      a2[(index[i] + 1):index[i + 1]] <- c(0, rep(1, times = len[i] - 2), 0)
      a3[(index[i] + 1):index[i + 1]] <- c(1, rep(0, times = len[i] - 2), 1)
      a4[(index[i] + 1):index[i + 1]] <- c(rep(0, times = len[i]))
    } else if (len[i] == 1) {
      a1[(index[i] + 1):index[i + 1]] <- 0
      a2[(index[i] + 1):index[i + 1]] <- 0
      a3[(index[i] + 1):index[i + 1]] <- 0
      a4[(index[i] + 1):index[i + 1]] <- 1
    }
  }

  a1 <- a1[1:(nn - 1)]
  subdiag.col <- 1:(nn - 1)
  subdiag.row <- 2:nn

  row.vec <- c(subdiag.row, (1:nn), subdiag.col)
  col.vec <- c(subdiag.col, (1:nn), subdiag.row)
  list(row.vec = row.vec, col.vec = col.vec, a1 = a1, a2 = a2, a3 = a3, a4 = a4)
}

# Exchangeable inverse.
get_alpha_inv_ex <- function(alpha.new, diag.vec, BlockDiag) {
  methods::as(
    BlockDiag %*% Diagonal(x = (-alpha.new / ((1 - alpha.new) * (1 + (diag.vec - 1) * alpha.new)))) +
      Diagonal(x = ((1 + (diag.vec - 2) * alpha.new) / ((1 - alpha.new) * (1 + (diag.vec - 1) * alpha.new)) +
        alpha.new / ((1 - alpha.new) * (1 + (diag.vec - 1) * alpha.new)))),
    "symmetricMatrix"
  )
}

# M-dependent inverse.
get_alpha_inv_mdep <- function(alpha.new, len, row.vec, col.vec) {
  m <- length(alpha.new)
  mat.sizes <- sort(unique(len))
  mat.inverses <- list()

  for (i in seq_along(mat.sizes)) {
    if (mat.sizes[i] == 1) {
      mat.inverses[[i]] <- 1
    } else {
      mtmp <- min(m, mat.sizes[i] - 1)
      a1 <- list()
      a1[[1]] <- rep(1, mat.sizes[i])
      for (j in 1:mtmp) {
        a1[[j + 1]] <- rep(alpha.new[j], mat.sizes[i] - j)
      }
      tmp <- bandSparse(mat.sizes[i], k = c(0:mtmp), diagonals = a1, symmetric = TRUE)
      mat.inverses[[i]] <- as.vector(solve(tmp))
    }
  }
  mat.finder <- match(len, mat.sizes)
  corr.vec <- unlist(mat.inverses[mat.finder])
  methods::as(sparseMatrix(i = row.vec, j = col.vec, x = corr.vec), "symmetricMatrix")
}

# Unstructured inverse.
get_alpha_inv_unstruc <- function(alpha.new, len, row.vec, col.vec) {
  unstr.row <- NULL
  unstr.col <- NULL
  ml <- max(len)
  for (i in 2:ml) {
    unstr.row <- c(unstr.row, 1:(i - 1))
    unstr.col <- c(unstr.col, rep(i, each = i - 1))
  }
  unstr.row <- c(unstr.row, 1:ml)
  unstr.col <- c(unstr.col, 1:ml)
  xvec <- c(alpha.new, rep(1, ml))
  # The biggest matrix implied by the cluster sizes.
  biggestMat <- forceSymmetric(sparseMatrix(i = unstr.row, j = unstr.col, x = xvec))

  mat.sizes <- sort(unique(len))
  mat.inverses <- list()
  for (i in seq_along(mat.sizes)) {
    tmp <- biggestMat[1:mat.sizes[i], 1:mat.sizes[i]]
    mat.inverses[[i]] <- as.vector(solve(tmp))
  }
  mat.finder <- match(len, mat.sizes)
  corr.vec <- unlist(mat.inverses[mat.finder])
  methods::as(sparseMatrix(i = row.vec, j = col.vec, x = corr.vec), "symmetricMatrix")
}

# nolint end

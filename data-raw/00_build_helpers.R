################################################################################
# 00_build_helpers.R
#
# Pure (no I/O, no network) functions used by the build scripts. They live here,
# rather than inline in 05_county_estimates.R / 14_unsheltered_imputation.R, so
# that tests/testthat/test-build-helpers.R can unit-test them directly. Any new
# logic in the build that decides WHO GETS COUNTED WHERE belongs in this file
# with a unit test (see TESTING.md).
################################################################################

# Canonical CoC code: strip a fiscal year embedded by early HUD files
# ("AL07-500" -> "AL-500") and a trailing footnote letter ("MO-604a" ->
# "MO-604"). See BUG-001, BUG-007.
normalize_coc_code <- function(x) {
  x <- sub("^([A-Z]{2})[0-9]{2}-", "\\1-", as.character(x))
  sub("^([A-Z]{2}-[0-9]{3})[a-z]$", "\\1", x)
}

# Largest-remainder rounding that preserves the (rounded) group total.
round_preserve <- function(x) {
  f <- floor(x); need <- round(sum(x)) - sum(f)
  if (need > 0) { o <- order(x - f, decreasing = TRUE)[seq_len(need)]; f[o] <- f[o] + 1 }
  as.integer(f)
}

# Split `total` across units in proportion to D, subject to per-unit caps,
# pushing any excess onto units that still have headroom (water-filling).
# Conserves `total` whenever sum(cap) >= total.
water_fill <- function(total, D, cap) {
  n <- length(D); alloc <- numeric(n); active <- rep(TRUE, n); rem <- total
  cap[is.na(cap)] <- Inf; it <- 0
  while (rem > 1e-6 && any(active) && it < 200) {
    it <- it + 1
    sa <- sum(D[active]); if (sa <= 0) break
    give <- numeric(n); give[active] <- rem * D[active] / sa
    prov <- alloc + give
    over <- active & (prov > cap + 1e-9)
    if (!any(over)) { alloc <- prov; rem <- 0 }
    else {
      rem <- rem - sum(cap[over] - alloc[over])
      alloc[over] <- cap[over]; active[over] <- FALSE
    }
  }
  alloc
}

# BUG-008. HUD's boundary file for a year sometimes omits a CoC that reported a
# PIT count. Return the year whose polygon to borrow: the nearest year that has
# one, preferring the EARLIER year on a tie (boundaries are drawn before the
# count). NA if the CoC never has a polygon.
nearest_boundary_year <- function(year, years_with_polygon) {
  y <- years_with_polygon[years_with_polygon != year]
  if (!length(y)) return(NA_integer_)
  d <- abs(y - year)
  as.integer(min(y[d == min(d)]))
}

# BUG-009. Each county's PRIMARY CoC: the CoC covering the largest part of it,
# but only if that part is at least `min_share` of the county's area. A county
# that HUD's boundary file leaves (nearly) uncovered gets no primary CoC -- it
# is imputed -- instead of drawing on a neighbour that slivers into it.
#   ov: data.frame(fips, COCNUM, a) overlap areas; county_area: named by fips.
choose_primary <- function(ov, county_area, min_share = 0.01) {
  ov <- ov[ov$a > 0, ]
  ov$share <- ov$a / county_area[ov$fips]
  ov <- ov[order(ov$fips, -ov$a), ]
  dom <- ov[!duplicated(ov$fips), ]
  dom <- dom[!is.na(dom$share) & dom$share >= min_share, c("fips", "COCNUM", "share")]
  rownames(dom) <- NULL
  dom
}

# Sub-county / nested CoCs that are nobody's primary are assigned whole to the
# county containing most of them, so their count is not lost.
assign_orphans <- function(ov, dom, cocs, county_area = NULL) {
  orphan <- setdiff(cocs, dom$COCNUM)
  o <- ov[ov$COCNUM %in% orphan & ov$a > 0, ]
  o <- o[order(o$COCNUM, -o$a), ]
  o <- o[!duplicated(o$COCNUM), ]
  o$share <- if (is.null(county_area)) NA_real_ else o$a / county_area[o$fips]
  o <- o[, c("fips", "COCNUM", "share")]
  rownames(o) <- NULL
  o
}

# BUG-010. A state whose HUD state total exceeds the sum of the CoCs coded to
# it (resid > 0) holds part of a CoC coded to another state. That CoC must be
# (a) coded to a state that is SHORT (resid < 0) -- for Kansas City, MO-604 and
# Missouri -- and (b) large enough to contain the residual. Among eligible CoCs
# overlapping the host, take the largest overlap. Area alone is not enough: in
# pre-2016 boundary files MO-604 barely enters Kansas, and slivers of OK-503
# and MO-603 were larger.
#   host: state abbreviation; resid: named residuals by state;
#   cand_area: overlap area within `host`, named by COCNUM;
#   coc_total: PIT totals named by COCNUM.
#   prefer: the CoC identified as bi-state from the most recent (best-drawn)
#   boundary file; used whenever it is eligible, because pre-2016 files draw
#   MO-604 so that it barely enters Kansas and MO-606's sliver outsizes it.
pick_split_coc <- function(host, resid, cand_area, coc_total, prefer = NULL) {
  short <- names(resid)[!is.na(resid) & resid < 0]
  tot <- coc_total[names(cand_area)]
  ok <- cand_area[substr(names(cand_area), 1, 2) %in% short & cand_area > 0 &
                    !is.na(tot) & tot > resid[[host]]]
  if (!length(ok)) return(NA_character_)
  if (!is.null(prefer) && !is.na(prefer[host]) && prefer[[host]] %in% names(ok))
    return(prefer[[host]])
  names(ok)[which.max(ok)]
}

# ---- unsheltered imputation (14_unsheltered_imputation.R) --------------------

# Which CoC-years count as a MISSING unsheltered count. Currently only the 2021
# COVID waiver: HUD let CoCs skip the unsheltered count, and those CoCs report
# 0. A 2021 zero is treated as missing when the CoC reported unsheltered people
# in BOTH neighbouring years with data (it normally counts them); a CoC that
# genuinely never finds unsheltered people keeps its 0.
flag_missing_unsheltered <- function(year, unsheltered, waiver_years = 2021L) {
  stopifnot(length(year) == length(unsheltered), !is.unsorted(year))
  miss <- logical(length(year))
  for (i in which(year %in% waiver_years & unsheltered == 0)) {
    before <- which(year < year[i] & !(year %in% waiver_years))
    after  <- which(year > year[i] & !(year %in% waiver_years))
    if (length(before) && length(after) &&
        unsheltered[max(before)] > 0 && unsheltered[min(after)] > 0)
      miss[i] <- TRUE
  }
  miss
}

# Impute the flagged values of one CoC's unsheltered series. The series is
# modelled on log(1 + y) with an automatically selected ARIMA that is REQUIRED
# to difference once (forecast::auto.arima(d = 1)); the missing points are then
# filled by Kalman SMOOTHING (imputeTS::na_kalman), so both earlier and later
# years inform the estimate. Back-transformed and rounded; never negative. If
# the series is too short to fit (< 6 observed years) or the fit fails, falls
# back to linear interpolation on the log scale. Returns list(value, method).
#
# Why d = 1: an unconstrained auto.arima usually picks a STATIONARY model,
# which pulls the gap toward the CoC's long-run mean -- dominated by the much
# lower counts of the late 2000s. In a holdout test on the 159 imputed CoCs
# (2019 and 2023 hidden and re-imputed) that version was 20% low in total with
# a 34% median error; with d = 1 it is 3-4% low with a 15-17% median error,
# matching log-linear interpolation. See data-raw/14_unsheltered_imputation.R.
impute_unsheltered_arima <- function(year, unsheltered, missing) {
  stopifnot(length(year) == length(unsheltered), length(missing) == length(year))
  if (!any(missing)) return(list(value = unsheltered, method = rep(NA_character_, length(year))))
  # regular annual grid so the time-series model sees gaps as gaps
  grid <- seq(min(year), max(year))
  z <- rep(NA_real_, length(grid))
  obs <- !missing
  z[match(year[obs], grid)] <- log1p(unsheltered[obs])
  tsz <- stats::ts(z)
  i <- match(year[missing], grid)
  method <- "arima_kalman"
  filled <- if (sum(!is.na(z)) >= 6) tryCatch(suppressWarnings({
    fit <- forecast::auto.arima(tsz, d = 1)
    imputeTS::na_kalman(tsz, model = fit$model)
  }), error = function(e) NULL) else NULL
  if (is.null(filled) || any(!is.finite(as.numeric(filled)[i]))) {
    method <- "log_linear_interp"
    filled <- imputeTS::na_interpolation(tsz, option = "linear")
  }
  val <- unsheltered
  val[missing] <- pmax(0L, as.integer(round(expm1(as.numeric(filled)[i]))))
  m <- rep(NA_character_, length(year)); m[missing] <- method
  list(value = val, method = m)
}

# Holdout validation of the imputer: for each CoC in `ids`, hide `hold_year`
# (dropping `exclude` years entirely), re-impute it, and return actual vs
# imputed. Used by 14_unsheltered_imputation.R to publish the backtest.
backtest_unsheltered <- function(pit, ids, hold_year, exclude = 2021L) {
  do.call(rbind, lapply(ids, function(k) {
    d <- pit[pit$coc_num == k & !pit$year %in% exclude, ]
    d <- d[order(d$year), ]
    m <- d$year == hold_year
    if (!any(m) || d$unsheltered[m] == 0) return(NULL)
    r <- impute_unsheltered_arima(d$year, d$unsheltered, m)
    data.frame(coc_num = k, hold_year = hold_year, actual = d$unsheltered[m],
               imputed = r$value[m], method = r$method[m])
  }))
}

## ---- external extractors (BUG-015) ---------------------------------------------
# The Python used for the .xlsb extractors: $COCHOMELESS_PYTHON if set, else the
# project venv data-raw/.venv (create it with
#   python3 -m venv data-raw/.venv && data-raw/.venv/bin/pip install -r data-raw/requirements.txt
# ), else python3 on the PATH. Returns "" when none is found.
build_python <- function(root = ".") {
  cand <- c(Sys.getenv("COCHOMELESS_PYTHON"),
            file.path(root, "data-raw", ".venv", "bin", "python"),
            file.path(root, "data-raw", ".venv", "Scripts", "python.exe"),
            Sys.which("python3"))
  hit <- cand[nzchar(cand) & file.exists(cand)]
  if (length(hit)) unname(hit[1]) else ""
}

# Run an external extractor that writes `out` from `src` (e.g. a Python .xlsb
# reader). A failed run must never let the build continue on a stale `out`:
#   * success                      -> `out` must exist and be newer than `src`;
#   * failure, `out` newer than src -> reuse it, with a warning (it was produced
#                                      from this very source file before);
#   * failure otherwise            -> stop().
# Returns the path of `out` invisibly.
run_extractor <- function(cmd, args, out, src) {
  if (!nzchar(cmd)) cmd <- NA_character_
  status <- if (is.na(cmd)) 127L else
    suppressWarnings(system2(cmd, args, stdout = "", stderr = ""))
  fresh <- function() file.exists(out) && file.exists(src) &&
    file.mtime(out) >= file.mtime(src)
  if (identical(as.integer(status), 0L)) {
    if (!fresh()) stop(sprintf("extractor reported success but %s is missing or older than %s",
                               out, src))
  } else if (fresh()) {
    warning(sprintf("extractor failed (status %s); reusing %s, which is newer than %s",
                    status, out, src), call. = FALSE)
  } else {
    stop(sprintf("extractor failed (status %s) and %s is missing or older than %s; ",
                 status, out, src),
         "set up the build Python: python3 -m venv data-raw/.venv && data-raw/.venv/bin/pip install -r data-raw/requirements.txt", call. = FALSE)
  }
  invisible(out)
}

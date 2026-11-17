#' Per-CoC Point-in-Time homeless counts by shelter status, 2007-2025
#'
#' HUD Point-in-Time (PIT) homeless counts for each Continuum of Care (CoC) and
#' year, split into sheltered and unsheltered components
#' (\code{sheltered + unsheltered = total}), in long format. Complements the
#' CoC-total \code{\link{hud2007}} objects and the national \code{\link{pit_us}}
#' series.
#'
#' \strong{2021:} HUD waived the unsheltered count for many CoCs during
#' COVID-19, so many CoCs report 0 unsheltered in 2021. The official columns
#' keep HUD's figures; \code{unsheltered_imp} / \code{total_imp} carry a
#' flagged imputation (see the section below).
#'
#' @format A data frame with one row per CoC-year and 9 variables:
#' \describe{
#'   \item{coc_num}{CoC number, e.g. \code{"WA-500"}.}
#'   \item{year}{Year of the count.}
#'   \item{total}{Overall homeless (PIT), as published by HUD.}
#'   \item{sheltered}{Sheltered homeless, as published by HUD.}
#'   \item{unsheltered}{Unsheltered homeless, as published by HUD.}
#'   \item{total_imp}{\code{sheltered + unsheltered_imp}. Equals \code{total}
#'     except where \code{unsheltered_imputed} is \code{TRUE}.}
#'   \item{unsheltered_imp}{Unsheltered homeless with the 2021 waiver gap
#'     imputed. Equals \code{unsheltered} except where
#'     \code{unsheltered_imputed} is \code{TRUE}.}
#'   \item{unsheltered_imputed}{\code{TRUE} if \code{unsheltered_imp} is an
#'     imputed value, not a HUD count. Only ever \code{TRUE} in 2021.}
#'   \item{imputation_method}{\code{"arima_kalman"}, or
#'     \code{"log_linear_interp"} for series too short to fit an ARIMA;
#'     \code{NA} for HUD counts.}
#' }
#' @section Imputed 2021 unsheltered counts:
#' HUD's COVID-19 waiver let CoCs skip the 2021 unsheltered count, and many
#' report 0. The \code{_imp} columns carry an estimate for those CoC-years;
#' HUD's official \code{total}, \code{sheltered} and \code{unsheltered} are
#' never modified. A 2021 zero is imputed only when the CoC counted unsheltered
#' people in the years either side (159 CoCs); the estimate is a
#' once-differenced ARIMA on \code{log(1 + unsheltered)} with Kalman smoothing,
#' so both earlier and later years inform it. In a holdout test (2019 and 2023
#' hidden and re-imputed for the same CoCs) it was 3-4\% low in total with a
#' 15-17\% median per-CoC error. Use the official columns to reproduce HUD; use
#' the \code{_imp} columns for trends across 2021. The same note is attached to
#' the data as \code{attr(x, "note")}. See
#' \code{vignette("unsheltered-imputation", package = "COCHomeless")}.
#' @source HUD AHAR Part 1 PIT estimates, from the PIT-by-CoC workbook
#'   (see \code{\link{hud2007}}). Imputation: \code{data-raw/14_unsheltered_imputation.R}.
"pit_coc"

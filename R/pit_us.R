#' National Point-in-Time homeless totals by shelter status, 2007-2025
#'
#' United States annual Point-in-Time (PIT) homeless counts split into sheltered
#' and unsheltered components (\code{sheltered + unsheltered = total}). The 2021
#' official \code{unsheltered} figure understates homelessness because HUD
#' waived the unsheltered count for many CoCs during COVID-19; the \code{_imp}
#' columns add the imputed unsheltered people of the 159 affected CoCs.
#'
#' @format A data frame with one row per year and 7 variables:
#' \describe{
#'   \item{year}{Year of the count.}
#'   \item{total}{Overall homeless (PIT), as published by HUD.}
#'   \item{sheltered}{Sheltered homeless (emergency shelter, transitional
#'     housing, safe haven).}
#'   \item{unsheltered}{Unsheltered homeless, as published by HUD.}
#'   \item{n_coc_imputed}{Number of CoCs whose unsheltered count was imputed
#'     that year (non-zero only in 2021).}
#'   \item{unsheltered_imp}{\code{unsheltered} plus the imputed CoC values; the
#'     sum of \code{\link{pit_coc}}\code{$unsheltered_imp}.}
#'   \item{total_imp}{\code{sheltered + unsheltered_imp}.}
#' }
#' @section Imputed 2021 unsheltered counts:
#' HUD's COVID-19 waiver let CoCs skip the 2021 unsheltered count, and many
#' report 0. The \code{_imp} columns carry an estimate for those CoC-years;
#' HUD's official \code{total}, \code{sheltered} and \code{unsheltered} are
#' never modified. A 2021 zero is imputed only when the CoC counted unsheltered
#' people in the years either side (159 CoCs, including territory CoCs); the estimate is a
#' once-differenced ARIMA on \code{log(1 + unsheltered)} with Kalman smoothing,
#' so both earlier and later years inform it. In a holdout test (2019 and 2023
#' hidden and re-imputed for the same CoCs) it was 3-4\% low in total with a
#' 15-17\% median per-CoC error. Use the official columns to reproduce HUD; use
#' the \code{_imp} columns for trends across 2021. The same note is attached to
#' the data as \code{attr(x, "note")}. See
#' \code{vignette("unsheltered-imputation", package = "COCHomeless")}.
#' @source HUD AHAR Part 1 PIT estimates, national totals computed from the
#'   PIT-by-CoC workbook (see \code{\link{hud2007}}).
"pit_us"

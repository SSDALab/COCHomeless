#' County-level homeless estimates by shelter status, 2007-2025
#'
#' County homeless estimates split into sheltered and unsheltered components
#' (\code{sheltered + unsheltered = total}), long format. The county total is
#' the disaggregated estimate from \code{\link{homeless}}; it is split using the
#' shelter ratio of the CoC the county was apportioned from (its primary CoC in
#' \code{\link{county_coc_alloc}}, with \code{\link{pit_coc}}). Counties with
#' no CoC (imputed in \code{homeless}) use the national ratio. Join to county
#' geography by \code{fips} (e.g. \code{\link{counties}} or
#' \code{\link{sp_homeless}}); the same sheltered/unsheltered values are also
#' carried on \code{sp_homeless} as \code{sheltered<yy>} /
#' \code{unsheltered<yy>}.
#'
#' @format A data frame with one row per county-year and 8 variables:
#' \describe{
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{year}{Year.}
#'   \item{total}{Estimated total homeless.}
#'   \item{sheltered}{Estimated sheltered homeless.}
#'   \item{unsheltered}{Estimated unsheltered homeless.}
#'   \item{total_imp}{\code{sheltered + unsheltered_imp}.}
#'   \item{unsheltered_imp}{\code{unsheltered} plus the county's share of its
#'     CoCs' imputed 2021 unsheltered people, split exactly as the county
#'     estimates are (\code{\link{county_coc_alloc}}).}
#'   \item{unsheltered_imputed}{\code{TRUE} if \code{unsheltered_imp} includes
#'     imputed people. Only ever \code{TRUE} in 2021. Counties with no CoC
#'     (imputed by the spatial model in \code{homeless}) are not adjusted.}
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
#' @source HUD PIT counts disaggregated to counties; see \code{\link{homeless}}.
"county_pit"

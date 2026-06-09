#' Per-CoC Point-in-Time homeless counts by shelter status, 2007-2025
#'
#' HUD Point-in-Time (PIT) homeless counts for each Continuum of Care (CoC) and
#' year, split into sheltered and unsheltered components
#' (\code{sheltered + unsheltered = total}), in long format. Complements the
#' CoC-total \code{\link{hud2007}} objects and the national \code{\link{pit_us}}
#' series. Note the 2021 \code{unsheltered} values: HUD waived the unsheltered
#' count for many CoCs during COVID-19, so many CoCs report 0 unsheltered in
#' 2021.
#'
#' @format A data frame with one row per CoC-year and 5 variables:
#' \describe{
#'   \item{coc_num}{CoC number, e.g. \code{"WA-500"}.}
#'   \item{year}{Year of the count.}
#'   \item{total}{Overall homeless (PIT).}
#'   \item{sheltered}{Sheltered homeless.}
#'   \item{unsheltered}{Unsheltered homeless.}
#' }
#' @source HUD AHAR Part 1 PIT estimates, from the PIT-by-CoC workbook
#'   (see \code{\link{hud2007}}).
"pit_coc"

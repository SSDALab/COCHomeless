#' National Point-in-Time homeless totals by shelter status, 2007-2025
#'
#' United States annual Point-in-Time (PIT) homeless counts split into sheltered
#' and unsheltered components (\code{sheltered + unsheltered = total}). Note the
#' 2021 \code{unsheltered} figure: HUD waived the unsheltered count for many
#' Continuum of Care areas during the COVID-19 pandemic, so 2021 understates
#' true homelessness and is a natural candidate for time-series imputation.
#'
#' @format A data frame with one row per year and 4 variables:
#' \describe{
#'   \item{year}{Year of the count.}
#'   \item{total}{Overall homeless (PIT).}
#'   \item{sheltered}{Sheltered homeless (emergency shelter, transitional
#'     housing, safe haven).}
#'   \item{unsheltered}{Unsheltered homeless.}
#' }
#' @source HUD AHAR Part 1 PIT estimates, national totals computed from the
#'   PIT-by-CoC workbook (see \code{\link{hud2007}}).
"pit_us"

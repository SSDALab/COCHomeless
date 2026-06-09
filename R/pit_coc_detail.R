#' Detailed CoC Point-in-Time counts by shelter type and subpopulation
#'
#' HUD Point-in-Time counts for each Continuum of Care (CoC) and year, broken
#' down by shelter type and subpopulation -- including household type
#' (individuals, families), veterans, chronically homeless, youth, and the
#' demographic breakdowns HUD reports (gender, race/ethnicity, age). Long
#' format, one row per CoC x year x shelter x subpopulation.
#'
#' The grid is completed across years, so a subpopulation HUD only began
#' reporting in a later year (or a category whose definition changed, e.g. the
#' 2023 race/ethnicity revision) is \code{NA} in years it was not collected
#' rather than missing. Join to CoC geography by \code{coc_num} (=
#' \code{coc2024$COCNUM}); for a county version see \code{\link{county_pit_detail}}.
#'
#' @format A data frame with one row per CoC-year-shelter-subpopulation and 5
#'   variables:
#' \describe{
#'   \item{coc_num}{CoC number, e.g. \code{"WA-500"}.}
#'   \item{year}{Year.}
#'   \item{shelter}{Shelter type: \code{Overall}, \code{Sheltered Total},
#'     \code{Sheltered ES} (emergency shelter), \code{Sheltered TH}
#'     (transitional housing), \code{Sheltered SH} (safe haven), or
#'     \code{Unsheltered}.}
#'   \item{subpopulation}{Subpopulation / demographic category (\code{All} for
#'     the unrestricted count).}
#'   \item{count}{Number of people (\code{NA} if not collected that year).}
#' }
#' @source HUD AHAR Part 1 PIT estimates, from the PIT-by-CoC workbook
#'   (see \code{\link{hud2007}}).
"pit_coc_detail"

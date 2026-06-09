#' Detailed county Point-in-Time estimates by shelter type and subpopulation
#'
#' The shelter-type and subpopulation breakdowns of \code{\link{pit_coc_detail}}
#' apportioned to counties through the Census-to-CoC crosswalk. A county's value
#' for each (shelter, subpopulation) is its disaggregated total (from
#' \code{\link{homeless}}) scaled by its dominant CoC's share of that category.
#' Long format; join to county geography by \code{fips} (e.g.
#' \code{\link{counties}}). As in \code{\link{pit_coc_detail}}, gender is
#' available 2013--2024 only (\code{NA} from 2025 onward, dropped by HUD).
#'
#' @format A data frame with one row per county-year-shelter-subpopulation and 5
#'   variables:
#' \describe{
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{year}{Year.}
#'   \item{shelter}{Shelter type (see \code{\link{pit_coc_detail}}).}
#'   \item{subpopulation}{Subpopulation / demographic category.}
#'   \item{count}{Estimated number of people.}
#' }
#' @source HUD PIT subpopulation counts (\code{\link{pit_coc_detail}})
#'   apportioned to counties; see \code{\link{homeless}}.
"county_pit_detail"

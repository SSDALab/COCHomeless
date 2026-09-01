#' Area for all U.S. counties and county equivalents
#'
#' Area in square kilometres for every county in the canonical county frame
#' (\code{\link{counties}}), including the District of Columbia and the U.S.
#' territories.
#'
#' Area is land plus water (Census \code{ALAND + AWATER}). Water is included
#' because the original series was built by summing census-tract polygons, and
#' coastal and Great Lakes tracts extend over water: Keweenaw County, Michigan
#' measures 15,452 km2 on that basis against 1,520 km2 of land. Keeping the same
#' denominator keeps the population-density weights used by the county
#' apportionment comparable with the published estimates of Almquist, Helwig and
#' You (2020).
#'
#' Used as the denominator of \code{density} in \code{\link{homeless}} and as the
#' weight in the CoC-to-county apportionment.
#'
#' @format A data frame with one row per county and 2 variables:
#' \describe{
#'   \item{fips}{Five-digit FIPS code uniquely identifying a county or county
#'     equivalent in the United States.}
#'   \item{skm}{Area, in square kilometres (land plus water).}
#' }
#' @source U.S. Census Bureau TIGER/Line cartographic boundary files, via the
#'   \pkg{tigris} package.
#' @seealso \code{\link{counties}} for the county frame this is keyed on.
"area"

#' U.S. county boundaries
#'
#' Cartographic boundaries (1:500,000) for all U.S. counties and county
#' equivalents, as a national \code{sf} object. Geometries are simplified for a
#' compact package size. Use as a base layer for mapping the county-level
#' estimates (\code{\link{homeless}}) and with the Census-to-CoC crosswalk.
#'
#' @format An \code{sf} data frame (CRS EPSG:4269, NAD83) with one row per
#'   county and 8 attributes plus geometry:
#' \describe{
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{STATEFP}{2-digit state FIPS code.}
#'   \item{COUNTYFP}{3-digit county FIPS code.}
#'   \item{NAME}{County name.}
#'   \item{NAMELSAD}{County name with legal/statistical description.}
#'   \item{STUSPS}{Two-letter state abbreviation.}
#'   \item{STATE_NAME}{State name.}
#'   \item{ALAND}{Land area in square meters.}
#'   \item{geometry}{County boundary polygon.}
#' }
#' @source U.S. Census Bureau TIGER/Line cartographic boundary files, via the
#'   \pkg{tigris} package (\url{https://www.census.gov/geographies/mapping-files.html}).
"counties"

#' U.S. state and territory boundaries
#'
#' Cartographic boundaries (1:500,000) for all U.S. states, the District of
#' Columbia, and territories, as a national \code{sf} object. Geometries are
#' simplified for a compact package size. Use as a base layer for national maps.
#'
#' @format An \code{sf} data frame (CRS EPSG:4269, NAD83) with one row per
#'   state/territory and 4 attributes plus geometry:
#' \describe{
#'   \item{state_fips}{2-digit state/territory FIPS code.}
#'   \item{STATEFP}{2-digit state/territory FIPS code.}
#'   \item{STUSPS}{Two-letter state/territory abbreviation.}
#'   \item{NAME}{State/territory name.}
#'   \item{ALAND}{Land area in square meters.}
#'   \item{geometry}{State/territory boundary polygon.}
#' }
#' @source U.S. Census Bureau TIGER/Line cartographic boundary files, via the
#'   \pkg{tigris} package.
"states"

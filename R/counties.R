#' U.S. county boundaries
#'
#' Cartographic boundaries (1:500,000) for all U.S. counties and county
#' equivalents, as a national \code{sf} object. Geometries are simplified for a
#' compact package size. Use as a base layer for mapping the county-level
#' estimates (\code{\link{homeless}}) and with the Census-to-CoC crosswalk.
#'
#' This object defines the \strong{canonical county FIPS vintage} for the whole
#' package: \code{area}, \code{homeless}, \code{homeless_na},
#' \code{sp_homeless}, \code{county_pit}, \code{county_pit_detail} and the
#' \code{county_coc*} / \code{tract_coc*} crosswalks are all keyed on it.
#' County codes change over time -- Connecticut replaced its eight counties
#' (09001-09015) with nine planning regions (09110-09190), Alaska split
#' Valdez-Cordova into Chugach (02063) and Copper River (02066) and renamed
#' Wade Hampton to Kusilvak (02158), and South Dakota renamed Shannon to Oglala
#' Lakota (46102) -- so joining data built on different vintages returns nothing
#' for the affected counties. The frame is pinned to the 2024 TIGER/Line vintage.
#'
#' @format An \code{sf} data frame (CRS EPSG:4269, NAD83) with one row per
#'   county and 9 attributes plus geometry:
#' \describe{
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{STATEFP}{2-digit state FIPS code.}
#'   \item{COUNTYFP}{3-digit county FIPS code.}
#'   \item{NAME}{County name.}
#'   \item{NAMELSAD}{County name with legal/statistical description.}
#'   \item{STUSPS}{Two-letter state abbreviation.}
#'   \item{STATE_NAME}{State name.}
#'   \item{ALAND}{Land area in square meters.}
#'   \item{AWATER}{Water area in square meters.}
#'   \item{geometry}{County boundary polygon.}
#' }
#' @source U.S. Census Bureau TIGER/Line cartographic boundary files, via the
#'   \pkg{tigris} package (\url{https://www.census.gov/geographies/mapping-files.html}).
"counties"

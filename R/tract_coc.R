#' Census tract to Continuum of Care (CoC) hard assignment crosswalk
#'
#' Assigns each U.S. census tract to the single HUD Continuum of Care (CoC)
#' that contains the tract's interior point. Built by a tract-centroid
#' point-in-polygon match (\code{sf::st_point_on_surface} then
#' \code{sf::st_join}) of IPUMS NHGIS tract polygons against the HUD CoC GIS
#' National Boundary files. Use it to attach a CoC label to any tract- or
#' county-keyed dataset. One row per tract; a small number of coastal/water
#' tracts whose interior point falls outside every CoC have \code{NA} CoC
#' fields.
#'
#' The matching procedure is due to Tom Byrne (Boston University); please credit
#' Byrne and his crosswalk repository,
#' \url{https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk}, when using
#' these crosswalk data. See \code{\link{COCHomeless}}.
#'
#' @format A data frame with one row per census tract and 9 variables:
#' \describe{
#'   \item{GEOID}{11-digit census tract identifier (state + county + tract).}
#'   \item{STATEFP}{2-digit state FIPS code.}
#'   \item{COUNTYFP}{3-digit county FIPS code.}
#'   \item{fips}{5-digit county FIPS code (\code{STATEFP} + \code{COUNTYFP}).}
#'   \item{TRACTCE}{6-digit census tract code.}
#'   \item{ST}{Two-letter state abbreviation.}
#'   \item{STATE_NAME}{State name.}
#'   \item{COCNUM}{CoC number, e.g. \code{"WA-500"} (\code{NA} if unmatched).}
#'   \item{COCNAME}{CoC name (\code{NA} if unmatched).}
#' }
#' @source HUD CoC GIS National Boundary files
#'   (\url{https://www.hudexchange.info/programs/coc/gis-tools/}); tract
#'   geography from IPUMS NHGIS (\url{https://www.nhgis.org/}). Crosswalk
#'   procedure adapted from Tom Byrne's \code{tract_coc_match} program.
#' @name tract_coc
#' @aliases tract_coc2019 tract_coc2022
"tract_coc2019"

#' @rdname tract_coc
"tract_coc2022"

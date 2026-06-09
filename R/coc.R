#' CoC geographic boundaries, 2007-2025
#'
#' HUD Continuum of Care (CoC) boundary polygons by year, \code{coc2007}
#' through \code{coc2024}, as national simple-feature (\code{sf}) objects with
#' one row per CoC. Built from HUD's per-state CoC GIS shapefiles, combined
#' nationally, with CoC codes harmonized across vintages (an embedded fiscal
#' year such as \code{"AL07-500"} is normalized to \code{"AL-500"}). Geometries
#' are topology-preserving simplified (about 2 percent of vertices retained) to
#' keep the package a manageable size; they are intended for national-scale
#' mapping and areal analysis rather than fine local cartography.
#'
#' @format An \code{sf} data frame (CRS EPSG:4269, NAD83) with one row per CoC
#'   and 4 attributes plus geometry:
#' \describe{
#'   \item{COCNUM}{CoC number, e.g. \code{"WA-500"}.}
#'   \item{COCNAME}{CoC name.}
#'   \item{ST}{Two-letter state/territory abbreviation.}
#'   \item{STATE_NAME}{State/territory name.}
#'   \item{geometry}{CoC boundary polygon.}
#' }
#' @source HUD CoC GIS tools:
#'   \url{https://www.hudexchange.info/programs/coc/gis-tools/}
#' @name coc
#' @aliases coc2007 coc2008 coc2009 coc2010 coc2011 coc2012 coc2013 coc2014 coc2015 coc2016 coc2017 coc2018 coc2019 coc2020 coc2021 coc2022 coc2023 coc2024 coc2025
"coc2007"

#' @rdname coc
"coc2008"

#' @rdname coc
"coc2009"

#' @rdname coc
"coc2010"

#' @rdname coc
"coc2011"

#' @rdname coc
"coc2012"

#' @rdname coc
"coc2013"

#' @rdname coc
"coc2014"

#' @rdname coc
"coc2015"

#' @rdname coc
"coc2016"

#' @rdname coc
"coc2017"

#' @rdname coc
"coc2018"

#' @rdname coc
"coc2019"

#' @rdname coc
"coc2020"

#' @rdname coc
"coc2021"

#' @rdname coc
"coc2022"

#' @rdname coc
"coc2023"

#' @rdname coc
"coc2024"

#' @rdname coc
"coc2025"

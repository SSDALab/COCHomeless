#' Tract to CoC area-weighted overlap crosswalk
#'
#' Area-weighted overlap between census tracts and HUD Continuum of Care (CoC)
#' boundaries, for tracts that straddle CoC borders. Computed from the
#' intersection of tract and CoC polygons in an equal-area projection
#' (EPSG:5070). Use it to apportion tract-level American Community Survey
#' values across CoCs (weights sum to 1 within each tract). For the
#' county-level apportionment of CoC counts see \code{\link{county_coc2019}}.
#'
#' Crosswalk procedure due to Tom Byrne (Boston University); please credit Byrne
#' and his repository
#' (\url{https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk}) when using
#' these data.
#'
#' @format A data frame with one row per (tract, CoC) overlap and 5 variables:
#' \describe{
#'   \item{GEOID}{11-digit census tract identifier.}
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{COCNUM}{CoC number.}
#'   \item{COCNAME}{CoC name.}
#'   \item{w_tract}{Share of the tract's area in this CoC; sums to 1 per tract.}
#' }
#' @source HUD CoC GIS National Boundary files; IPUMS NHGIS tract geography.
#'   See \code{\link{tract_coc2019}}.
#' @name tract_coc_wt
#' @aliases tract_coc_wt2007 tract_coc_wt2008 tract_coc_wt2009 tract_coc_wt2010 tract_coc_wt2011 tract_coc_wt2012 tract_coc_wt2013 tract_coc_wt2014 tract_coc_wt2015 tract_coc_wt2016 tract_coc_wt2017 tract_coc_wt2018 tract_coc_wt2019 tract_coc_wt2020 tract_coc_wt2021 tract_coc_wt2022 tract_coc_wt2023 tract_coc_wt2024 tract_coc_wt2025
"tract_coc_wt2007"

#' @rdname tract_coc_wt
"tract_coc_wt2008"

#' @rdname tract_coc_wt
"tract_coc_wt2009"

#' @rdname tract_coc_wt
"tract_coc_wt2010"

#' @rdname tract_coc_wt
"tract_coc_wt2011"

#' @rdname tract_coc_wt
"tract_coc_wt2012"

#' @rdname tract_coc_wt
"tract_coc_wt2013"

#' @rdname tract_coc_wt
"tract_coc_wt2014"

#' @rdname tract_coc_wt
"tract_coc_wt2015"

#' @rdname tract_coc_wt
"tract_coc_wt2016"

#' @rdname tract_coc_wt
"tract_coc_wt2017"

#' @rdname tract_coc_wt
"tract_coc_wt2018"

#' @rdname tract_coc_wt
"tract_coc_wt2019"

#' @rdname tract_coc_wt
"tract_coc_wt2020"

#' @rdname tract_coc_wt
"tract_coc_wt2021"

#' @rdname tract_coc_wt
"tract_coc_wt2022"

#' @rdname tract_coc_wt
"tract_coc_wt2023"

#' @rdname tract_coc_wt
"tract_coc_wt2024"

#' @rdname tract_coc_wt
"tract_coc_wt2025"

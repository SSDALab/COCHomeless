#' County to CoC area-weighted crosswalk
#'
#' Area-weighted overlap between U.S. counties and HUD Continuum of Care (CoC)
#' boundaries, with two normalizations supporting both directions of
#' apportionment. Computed by aggregating the tract-by-CoC intersection to the
#' county level in an equal-area projection (EPSG:5070).
#'
#' \itemize{
#'   \item \code{w_coc} apportions a CoC's Point-in-Time count \emph{down} to
#'     its counties (sums to 1 within each \code{COCNUM}). This is the weight
#'     used to build the county-level estimates in \code{\link{homeless}},
#'     following Almquist, Helwig and You (2020).
#'   \item \code{w_county} aggregates county data \emph{up} to CoCs (sums to 1
#'     within each \code{fips}).
#' }
#'
#' Crosswalk procedure due to Tom Byrne (Boston University); please credit Byrne
#' and his repository
#' (\url{https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk}) when using
#' these data.
#'
#' @format A data frame with one row per (county, CoC) overlap and 6 variables:
#' \describe{
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{COCNUM}{CoC number.}
#'   \item{COCNAME}{CoC name.}
#'   \item{area_m2}{Overlap area in square meters (EPSG:5070).}
#'   \item{w_coc}{Share of the CoC's area in this county; sums to 1 per CoC.}
#'   \item{w_county}{Share of the county's area in this CoC; sums to 1 per county.}
#' }
#' @source HUD CoC GIS National Boundary files; IPUMS NHGIS tract geography.
#'   See \code{\link{tract_coc2019}}.
#' @references Almquist, Z. W., Helwig, N. E. and You, Y. (2020). Connecting
#'   Continuum of Care point-in-time homeless counts to United States Census
#'   areal units. \emph{Mathematical Population Studies}, 27(1), 46--58.
#'   \doi{10.1080/08898480.2019.1636574}
#' @name county_coc
#' @aliases county_coc2007 county_coc2008 county_coc2009 county_coc2010 county_coc2011 county_coc2012 county_coc2013 county_coc2014 county_coc2015 county_coc2016 county_coc2017 county_coc2018 county_coc2019 county_coc2020 county_coc2021 county_coc2022 county_coc2023 county_coc2024 county_coc2025
"county_coc2007"

#' @rdname county_coc
"county_coc2008"

#' @rdname county_coc
"county_coc2009"

#' @rdname county_coc
"county_coc2010"

#' @rdname county_coc
"county_coc2011"

#' @rdname county_coc
"county_coc2012"

#' @rdname county_coc
"county_coc2013"

#' @rdname county_coc
"county_coc2014"

#' @rdname county_coc
"county_coc2015"

#' @rdname county_coc
"county_coc2016"

#' @rdname county_coc
"county_coc2017"

#' @rdname county_coc
"county_coc2018"

#' @rdname county_coc
"county_coc2019"

#' @rdname county_coc
"county_coc2020"

#' @rdname county_coc
"county_coc2021"

#' @rdname county_coc
"county_coc2022"

#' @rdname county_coc
"county_coc2023"

#' @rdname county_coc
"county_coc2024"

#' @rdname county_coc
"county_coc2025"

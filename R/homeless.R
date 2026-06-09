#' County-level homeless estimates, 2007-2024 (missing values imputed)
#'
#' County-level homeless counts with missing values imputed, plus selected
#' American Community Survey (ACS) demographic covariates. Counts are produced
#' by disaggregating HUD Continuum of Care (CoC) Point-in-Time counts to
#' counties using population-density weighting and imputing counties with no CoC
#' via a spatial Poisson model, following Almquist, Helwig and You (2020)
#' \doi{10.1080/08898480.2019.1636574}. See \code{\link{homeless_na}} for the
#' pre-imputation version.
#'
#' Estimates are bounded by a plausibility cap of 2,000 homeless per 100,000
#' residents (2 percent of population), or 3,500 per 100,000 for the dense
#' major-metro cores (New York City boroughs and Los Angeles County). The cap is
#' applied by redistributing any excess within the same CoC, so a CoC's
#' Point-in-Time total is preserved across its counties. HUD CoC counts
#' (\code{\link{hud2007}}) are never altered (none exceed the cap in any year).
#'
#' @format A data frame with 3143 rows (counties and county equivalents in the
#'   50 states and DC) and the following variables:
#' \describe{
#'   \item{state}{Two-digit state FIPS code.}
#'   \item{fips}{Five-digit county FIPS code.}
#'   \item{count07}{Estimated homeless count, 2007 (imputed where missing).}
#'   \item{count08}{Estimated homeless count, 2008.}
#'   \item{count09}{Estimated homeless count, 2009.}
#'   \item{count10}{Estimated homeless count, 2010.}
#'   \item{count11}{Estimated homeless count, 2011.}
#'   \item{count12}{Estimated homeless count, 2012.}
#'   \item{count13}{Estimated homeless count, 2013.}
#'   \item{count14}{Estimated homeless count, 2014.}
#'   \item{count15}{Estimated homeless count, 2015.}
#'   \item{count16}{Estimated homeless count, 2016.}
#'   \item{count17}{Estimated homeless count, 2017.}
#'   \item{count18}{Estimated homeless count, 2018.}
#'   \item{count19}{Estimated homeless count, 2019.}
#'   \item{count20}{Estimated homeless count, 2020.}
#'   \item{count21}{Estimated homeless count, 2021.}
#'   \item{count22}{Estimated homeless count, 2022.}
#'   \item{count23}{Estimated homeless count, 2023.}
#'   \item{count24}{Estimated homeless count, 2024.}
#'   \item{count25}{Estimated homeless count, 2025.}
#'   \item{population}{County population (ACS 5-year estimate).}
#'   \item{density}{Population density: 2010 Census population per square km.}
#'   \item{pctblack}{Percent Black population.}
#'   \item{pctageunder18}{Percent of population under 18.}
#'   \item{pctfoodstamp}{Percent of housing units receiving SNAP/food stamps.}
#'   \item{pctvacanthousing}{Percent of housing units vacant.}
#'   \item{pctmedhousingcost}{Median annual housing cost as a percent of median
#'     household income.}
#'   \item{medhousingval}{Median housing value, in $1,000.}
#'   \item{pctmarried}{Percent of population now married.}
#'   \item{avg}{Mean homeless count across 2007--2025.}
#'   \item{state_name}{State name.}
#' }
#' @source Homeless counts: HUD Point-in-Time data (see \code{\link{hud2007}})
#'   disaggregated to counties. Covariates: U.S. Census Bureau American
#'   Community Survey 5-year estimates, via the \pkg{tidycensus} package.
#' @references Almquist, Z. W., Helwig, N. E. and You, Y. (2020). Connecting
#'   Continuum of Care point-in-time homeless counts to United States Census
#'   areal units. \emph{Mathematical Population Studies}, 27(1), 46--58.
"homeless"

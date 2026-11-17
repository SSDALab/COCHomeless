#' Where each county estimate comes from: county x year x source CoC
#'
#' The exact apportionment behind \code{\link{homeless}},
#' \code{\link{county_pit}} and \code{\link{county_pit_detail}}: for every
#' county and year, each CoC whose PIT count contributed to the county's
#' estimate and how many people it contributed. Use it to trace a county figure
#' to its sources, to see which year's HUD boundary placed it, or to explain a
#' large year-over-year swing (a change of source CoC, or of a CoC's footprint,
#' moves a county's estimate even when no CoC's count changed much).
#'
#' Summing \code{count} by \code{coc_num} and \code{year} reproduces every
#' CoC's HUD count exactly (territory CoCs excepted: they have no counties).
#' Summing by \code{fips} and \code{year} reproduces \code{homeless_na},
#' except for a handful of counties lowered by the per-capita cap. Counties
#' absent in a year had no CoC and were imputed.
#'
#' @format A data frame with one row per county-year-CoC and 7 variables:
#' \describe{
#'   \item{fips}{5-digit county FIPS code.}
#'   \item{year}{Year.}
#'   \item{coc_num}{Contributing CoC.}
#'   \item{count}{People apportioned to this county from this CoC.}
#'   \item{role}{\code{"primary"}: the CoC covering the largest part of the
#'     county (at least 1\% of it). \code{"nested"}: a sub-county CoC (e.g. Long
#'     Beach inside Los Angeles County) assigned whole to the county holding most
#'     of it. \code{"bridged"}: the county's own CoC in a year when HUD's
#'     boundary file leaves the county out, though the CoC holds it in the years
#'     before and after (e.g. Yuba County in \code{CA-524}, 2011-2014); without
#'     this the county would be imputed on top of its CoC's count.
#'     \code{"bi-state"}: the Kansas portion of Kansas City's CoC
#'     (\code{MO-604}), split by HUD's published state totals.}
#'   \item{share}{Share of the county's area the CoC covers in that year's
#'     boundary file (below 1\% or 0 for bridged rows; \code{NA} for bi-state rows and nested CoCs in a county with its own primary).}
#'   \item{boundary_year}{Year of the HUD boundary file used to place the CoC.
#'     Differs from \code{year} when HUD's file for \code{year} omits the CoC;
#'     the nearest year's polygon is used (53 CoC-years, e.g. \code{CA-524}
#'     2009-2012, \code{LA-509} 2007-2014).}
#' }
#' @source Built by \code{data-raw/05_county_estimates.R}. Method: Almquist,
#'   Helwig and You (2020) <doi:10.1080/08898480.2019.1636574>.
"county_coc_alloc"

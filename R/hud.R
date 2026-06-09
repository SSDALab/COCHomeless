#' CoC-level Point-in-Time (PIT) homeless counts, 2007-2025
#'
#' Annual HUD Point-in-Time (PIT) estimates of the total homeless population
#' ("Overall Homeless") for each Continuum of Care (CoC). One data frame per
#' year, \code{hud2007} through \code{hud2024}, harmonized from HUD's unified
#' "PIT Counts by CoC" workbook so the CoC coding and count definition are
#' consistent across the series.
#'
#' Note: the 2021 totals are unusually low because HUD waived the unsheltered
#' count requirement for many CoCs during the COVID-19 pandemic.
#'
#' @format A data frame with one row per CoC and 2 variables:
#' \describe{
#'   \item{coc_num}{CoC number, e.g. \code{"WA-500"} (character).}
#'   \item{count}{Overall Homeless PIT count for the year (integer).}
#' }
#' @source HUD, Annual Homeless Assessment Report (AHAR) Part 1, PIT estimates:
#'   \url{https://www.huduser.gov/portal/datasets/ahar/2024-ahar-part-1-pit-estimates-of-homelessness-in-the-us.html}
#' @name hud
#' @aliases hud2007 hud2008 hud2009 hud2010 hud2011 hud2012 hud2013 hud2014 hud2015 hud2016 hud2017 hud2018 hud2019 hud2020 hud2021 hud2022 hud2023 hud2024 hud2025
"hud2007"

#' @rdname hud
"hud2008"

#' @rdname hud
"hud2009"

#' @rdname hud
"hud2010"

#' @rdname hud
"hud2011"

#' @rdname hud
"hud2012"

#' @rdname hud
"hud2013"

#' @rdname hud
"hud2014"

#' @rdname hud
"hud2015"

#' @rdname hud
"hud2016"

#' @rdname hud
"hud2017"

#' @rdname hud
"hud2018"

#' @rdname hud
"hud2019"

#' @rdname hud
"hud2020"

#' @rdname hud
"hud2021"

#' @rdname hud
"hud2022"

#' @rdname hud
"hud2023"

#' @rdname hud
"hud2024"

#' @rdname hud
"hud2025"

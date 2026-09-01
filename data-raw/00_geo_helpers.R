################################################################################
# 00_geo_helpers.R
#
# Shared geography helpers, sourced by 01_tract_coc_crosswalk.R and
# 05_county_estimates.R. Run from the package root.
#
# The point of this file is a single rule: NEVER take a county FIPS code from a
# census-tract attribute. Tract shapefiles carry the county code of their own
# vintage, and county codes are not stable -- Connecticut replaced its eight
# counties (09001-09015) with nine planning regions (09110-09190) in 2022-2024,
# Alaska split Valdez-Cordova into Chugach (02063) and Copper River (02066) and
# renamed Wade Hampton to Kusilvak (02158), and South Dakota renamed Shannon to
# Oglala Lakota (46102). Mixing vintages made whole states silently disappear
# from joins. Instead, every tract is assigned to the county whose polygon
# contains its interior point, on the canonical `counties` frame.
################################################################################

suppressMessages({ library(sf); library(dplyr) })

EQ <- 5070L   # Conus Albers, equal-area: all geometric work happens here

#' Normalize a tract layer to the fields the crosswalk needs, in EPSG:5070.
#' Deliberately does NOT derive `fips` -- see `tract_county_fips()`.
prep_tracts <- function(x) {
  x |> st_transform(EQ) |> st_make_valid() |>
    transmute(STATEFP, COUNTYFP, TRACTCE, GEOID)
}

#' Canonical county FIPS for each tract, by interior point in county polygon.
#'
#' @param tracts  an sf layer from `prep_tracts()`
#' @param counties the canonical county frame (data/counties.rda)
#' @param cache   path to an .rds cache; the assignment depends only on the
#'   tract vintage, so it is computed once per vintage rather than once per year
#' @return data.frame of GEOID + fips (fips is NA for tracts whose interior
#'   point falls outside every county, e.g. offshore water tracts)
tract_county_fips <- function(tracts, counties, cache = NULL) {
  if (!is.null(cache) && file.exists(cache)) return(readRDS(cache))
  co <- counties[, "fips"] |> st_transform(EQ) |> st_make_valid()
  pts <- suppressWarnings(st_point_on_surface(tracts[, "GEOID"]))
  out <- st_join(pts, co) |> st_drop_geometry() |>
    distinct(GEOID, .keep_all = TRUE)

  # A few dozen tracts are entirely offshore, so their interior point falls in
  # water outside every (shoreline-clipped) county polygon. They are real tracts
  # belonging to a real coastal county, so assign them to the nearest one rather
  # than losing them -- taking the county code from the tract attributes instead
  # would reintroduce the vintage mismatch this function exists to prevent.
  gap <- which(is.na(out$fips))
  if (length(gap)) {
    miss <- pts[match(out$GEOID[gap], pts$GEOID), ]
    out$fips[gap] <- co$fips[st_nearest_feature(miss, co)]
    message("  assigned ", length(gap), " offshore tracts to the nearest county")
  }
  if (!is.null(cache)) saveRDS(out, cache)
  out
}

#' Attach the canonical `fips` to a prepared tract layer.
add_county_fips <- function(tracts, counties, cache = NULL) {
  map <- tract_county_fips(tracts, counties, cache)
  tracts$fips <- map$fips[match(tracts$GEOID, map$GEOID)]
  tracts
}

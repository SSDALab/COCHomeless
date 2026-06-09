################################################################################
# 01_tract_coc_crosswalk.R
#
# Build the Census <-> Continuum of Care (CoC) crosswalk datasets.
#
# Two products per CoC vintage YEAR:
#   tract_cocYEAR     hard assignment: each census tract -> the single CoC that
#                     contains its interior point (st_point_on_surface), via a
#                     point-in-polygon join.  ~73k rows.  (Tom Byrne's method,
#                     adapted from 001_tract_coc_match.R.)
#   tract_coc_wtYEAR  area-weighted overlap: st_intersection of tract polygons
#                     with CoC polygons, giving each (tract, CoC) pair its share
#                     of the tract's area.  Tracts that straddle a CoC boundary
#                     split across rows; area shares per tract sum to 1.  Also
#                     rolled up to county -> CoC area weights (`fips`, `COCNUM`,
#                     `w_area`) for apportioning CoC counts down to counties in
#                     05_county_estimates.R.  Population weights are layered on
#                     there using tidycensus tract population.
#
# Inputs (HUD CoC GIS National Boundary geodatabases + an IPUMS NHGIS tract
# shapefile).  Point COC_CROSSWALK_DATA at the directory holding them; it
# defaults to the reference crosswalk repo used to develop this package.
#
# CREDIT: the tract-centroid point-in-polygon matching procedure is due to
# Tom Byrne (Boston University, tbyrne@bu.edu), from his program
# 001_tract_coc_match.R.  Please cite Byrne when using the crosswalk datasets.
################################################################################

suppressMessages({
  library(sf)
  library(dplyr)
})

data_dir <- Sys.getenv(
  "COC_CROSSWALK_DATA",
  unset = "~/Documents/back-up-oldMP/Back_up/github/SSDALab/World_Widd_Homelessness/CoC_Crosswalk/data"
)
data_dir <- path.expand(data_dir)

# Run this script from the package root (COCHomeless/); outputs land in data/.
out_dir <- "data"
if (!dir.exists(out_dir)) stop("run from the package root (COCHomeless/): no data/ dir")

sf::sf_use_s2(FALSE)  # avoid s2 point-in-polygon errors on HUD/NHGIS polygons

# Equal-area projection for all geometric work (areas, intersections,
# point-on-surface).  EPSG:5070 = NAD83 / Conus Albers (m).
EQ_AREA <- 5070L

## ---- inputs per vintage --------------------------------------------------
# Map each CoC boundary vintage to its geodatabase and the matching tract
# shapefile.  Extend this list as new HUD CoC GIS files are added (2016-2024).
vintages <- list(
  `2019` = list(
    coc   = file.path(data_dir, "CoC_GIS_National_Boundary_2019/FY19_CoC_National_Bnd.gdb"),
    tract = file.path(data_dir, "nhgis0013_shape/nhgis0013_shapefile_tl2019_us_tract_2019/US_tract_2019.shp")
  ),
  `2022` = list(
    coc   = file.path(data_dir, "CoC_GIS_National_Boundary_2022/CoC_GIS_National_Boundary.gdb"),
    # HUD CoC 2022 reuses the 2019 ACS tract geography (same vintage as Byrne).
    tract = file.path(data_dir, "nhgis0013_shape/nhgis0013_shapefile_tl2019_us_tract_2019/US_tract_2019.shp")
  )
)

build_crosswalk <- function(year, coc_path, tract_path) {
  message("== ", year, " ==")

  cocs <- st_read(coc_path, quiet = TRUE) |>
    st_transform(EQ_AREA) |>
    st_make_valid() |>
    transmute(ST, STATE_NAME, COCNUM, COCNAME)

  tracts <- st_read(tract_path, quiet = TRUE) |>
    st_transform(EQ_AREA) |>
    st_make_valid() |>
    transmute(STATEFP, COUNTYFP, TRACTCE, GEOID)

  ## hard assignment: tract interior point -> containing CoC
  pts <- st_point_on_surface(tracts)
  hard <- st_join(pts, cocs) |>
    st_drop_geometry() |>
    mutate(fips = paste0(STATEFP, COUNTYFP)) |>
    select(GEOID, STATEFP, COUNTYFP, fips, TRACTCE, ST, STATE_NAME, COCNUM, COCNAME)

  ## area-weighted overlap: intersect tract polygons with CoC polygons
  tracts$tract_area <- as.numeric(st_area(tracts))
  inter <- st_intersection(tracts, cocs)
  inter$piece_area <- as.numeric(st_area(inter))
  inter <- inter |>
    st_drop_geometry() |>
    mutate(fips = paste0(STATEFP, COUNTYFP)) |>
    filter(piece_area > 0)

  ## tract -> CoC: w_tract = share of the tract's area in each CoC (sums to 1
  ## per tract).  Use to aggregate tract-level ACS values up to CoCs.
  wt_tract <- inter |>
    mutate(w_tract = piece_area / tract_area) |>
    filter(w_tract > 1e-6) |>                      # drop slivers
    group_by(GEOID) |>
    mutate(w_tract = w_tract / sum(w_tract)) |>
    ungroup() |>
    select(GEOID, fips, COCNUM, COCNAME, w_tract)

  ## county <-> CoC overlap with two normalizations:
  ##   w_coc    = share of each CoC's area in a county  (sums to 1 per COCNUM)
  ##              -> apportion a CoC's PIT count DOWN to counties.
  ##   w_county = share of each county's area in a CoC  (sums to 1 per fips)
  ##              -> aggregate county data UP to CoCs.
  wt_county <- inter |>
    group_by(fips, COCNUM, COCNAME) |>
    summarise(area_m2 = sum(piece_area), .groups = "drop") |>
    group_by(COCNUM)  |> mutate(w_coc    = area_m2 / sum(area_m2)) |> ungroup() |>
    group_by(fips)    |> mutate(w_county = area_m2 / sum(area_m2)) |> ungroup()

  list(hard = hard, wt_tract = wt_tract, wt_county = wt_county)
}

for (yr in names(vintages)) {
  v <- vintages[[yr]]
  if (!file.exists(v$coc) || !file.exists(v$tract)) {
    message("skip ", yr, ": missing input(s)"); next
  }
  res <- build_crosswalk(yr, v$coc, v$tract)

  tract_coc    <- res$hard
  tract_coc_wt <- res$wt_tract
  county_coc   <- res$wt_county

  assign(paste0("tract_coc",    yr), tract_coc)
  assign(paste0("tract_coc_wt", yr), tract_coc_wt)
  assign(paste0("county_coc",   yr), county_coc)

  save(list = paste0("tract_coc",    yr), file = file.path(out_dir, paste0("tract_coc",    yr, ".rda")), compress = "xz")
  save(list = paste0("tract_coc_wt", yr), file = file.path(out_dir, paste0("tract_coc_wt", yr, ".rda")), compress = "xz")
  save(list = paste0("county_coc",   yr), file = file.path(out_dir, paste0("county_coc",   yr, ".rda")), compress = "xz")

  message(sprintf("  %s: %d tracts assigned, %d weighted pieces, %d county-CoC pairs",
                  yr, nrow(tract_coc), nrow(tract_coc_wt), nrow(county_coc)))
}

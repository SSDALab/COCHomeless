################################################################################
# 01_tract_coc_crosswalk.R
#
# Build the Census <-> Continuum of Care (CoC) crosswalk datasets for every year
# 2007-2025:
#   tract_cocYEAR     hard assignment of each census tract to the CoC containing
#                     its interior point (st_point_on_surface + st_join).
#   tract_coc_wtYEAR  area-weighted tract<->CoC overlap (w_tract sums to 1/tract).
#   county_cocYEAR    county<->CoC area weights (w_coc sums to 1/CoC; w_county
#                     sums to 1/county).
#
# Census tract geography changes only at the decennial census, so two tract
# vintages are used: 2010-census tracts (IPUMS NHGIS) for 2007-2019, and
# 2020-census tracts (tigris) for 2020-2025. Each year's tracts are matched
# against that year's CoC boundaries (the package coc<year> sf objects).
#
# Crosswalk procedure due to Tom Byrne; see
# https://github.com/tomhbyrne/HUD-CoC-Geography-Crosswalk
# Run from the package root. Requires CENSUS_API_KEY in ~/.Renviron (tigris).
################################################################################

suppressMessages({ library(sf); library(dplyr); library(tigris) })
sf_use_s2(FALSE)
options(tigris_use_cache = TRUE, tigris_class = "sf")
stopifnot(dir.exists("data"))
EQ <- 5070L
dl <- "data-raw/downloads"; dir.create(dl, showWarnings = FALSE, recursive = TRUE)

prep_tracts <- function(x) {
  x |> st_transform(EQ) |> st_make_valid() |>
    transmute(STATEFP, COUNTYFP, TRACTCE, GEOID,
              fips = paste0(STATEFP, COUNTYFP))
}

## ---- 2010-census tracts (IPUMS NHGIS) --------------------------------------
nhgis <- Sys.getenv("NHGIS_TRACTS_2019", paste0(
  "~/Documents/back-up-oldMP/Back_up/github/SSDALab/World_Widd_Homelessness/",
  "CoC_Crosswalk/data/nhgis0013_shape/nhgis0013_shapefile_tl2019_us_tract_2019/",
  "US_tract_2019.shp"))
tracts2010 <- prep_tracts(st_read(path.expand(nhgis), quiet = TRUE))
message("2010-vintage tracts: ", nrow(tracts2010))

## ---- 2020-census tracts (tigris, national, cached; loaded on first need) ----
.tracts2020 <- NULL
get_tracts2020 <- function() {
  if (!is.null(.tracts2020)) return(.tracts2020)
  t2020_cache <- file.path(dl, "tracts2020.rds")
  if (file.exists(t2020_cache)) {
    t <- readRDS(t2020_cache)
  } else {
    st_fips <- sort(union(unique(substr(tracts2010$fips, 1, 2)), c("02","15","72")))
    parts <- lapply(st_fips, function(s)
      tryCatch(tracts(state = s, year = 2020, cb = TRUE, progress_bar = FALSE),
               error = function(e) NULL))
    t <- prep_tracts(do.call(rbind, Filter(Negate(is.null), parts)))
    saveRDS(t, t2020_cache)
  }
  message("2020-vintage tracts: ", nrow(t))
  .tracts2020 <<- t; t
}

build_year <- function(yr) {
  tr <- if (yr <= 2019) tracts2010 else get_tracts2020()
  load(sprintf("data/coc%d.rda", yr)); coc <- get(sprintf("coc%d", yr))
  cc <- coc[, c("COCNUM", "COCNAME", "ST", "STATE_NAME")] |>
    st_transform(EQ) |> st_make_valid()

  ## hard assignment: tract interior point -> containing CoC
  pts <- suppressWarnings(st_point_on_surface(tr))
  hard <- st_join(pts, cc) |> st_drop_geometry() |>
    select(GEOID, STATEFP, COUNTYFP, fips, TRACTCE, ST, STATE_NAME, COCNUM, COCNAME) |>
    distinct(GEOID, .keep_all = TRUE)   # one CoC per tract (drop boundary dup matches)

  ## area-weighted overlap
  tr$tract_area <- as.numeric(st_area(tr))
  inter <- st_intersection(tr, cc)
  inter$piece_area <- as.numeric(st_area(inter))
  inter <- inter |> st_drop_geometry() |> filter(piece_area > 0)

  wt_tract <- inter |>
    mutate(w_tract = piece_area / tract_area) |>
    filter(w_tract > 1e-6) |>
    group_by(GEOID) |> mutate(w_tract = w_tract / sum(w_tract)) |> ungroup() |>
    select(GEOID, fips, COCNUM, COCNAME, w_tract)

  wt_county <- inter |>
    group_by(fips, COCNUM, COCNAME) |>
    summarise(area_m2 = sum(piece_area), .groups = "drop") |>
    group_by(COCNUM) |> mutate(w_coc = area_m2 / sum(area_m2)) |> ungroup() |>
    group_by(fips)   |> mutate(w_county = area_m2 / sum(area_m2)) |> ungroup()

  for (no in list(c("tract_coc","hard"), c("tract_coc_wt","wt_tract"),
                  c("county_coc","wt_county"))) {
    obj <- sprintf("%s%d", no[1], yr); assign(obj, get(no[2]))
    save(list = obj, file = file.path("data", paste0(obj, ".rda")), compress = "xz")
  }
  message(sprintf("  coc%d: %d tracts, %d CoCs, %d county-CoC pairs", yr,
                  nrow(hard), length(unique(stats::na.omit(hard$COCNUM))), nrow(wt_county)))
}

years <- as.integer(strsplit(Sys.getenv("XWALK_YEARS",
            paste(2007:2025, collapse = ",")), ",")[[1]])
for (y in years) { message("== ", y, " =="); build_year(y) }

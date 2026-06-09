################################################################################
# 07_base_geography.R
#
# Full U.S. base geography as sf, for mapping and for the CoC<->county/tract
# crosswalk and county estimates:
#   counties  all U.S. counties (cartographic 1:500k), fips + geometry
#   states    all U.S. states/territories (cartographic 1:500k)
#
# Pulled from the Census Bureau via tigris. Run from the package root.
################################################################################

suppressMessages({ library(tigris); library(sf) })
options(tigris_use_cache = TRUE, tigris_class = "sf")
stopifnot(dir.exists("data"))

yr <- as.integer(Sys.getenv("TIGER_YEAR", "2022"))

co <- counties(cb = TRUE, resolution = "500k", year = yr, progress_bar = FALSE)
counties <- st_transform(co, 4269)
counties <- counties[, intersect(c("GEOID", "STATEFP", "COUNTYFP", "NAME",
                                   "NAMELSAD", "STUSPS", "STATE_NAME", "ALAND"),
                                 names(counties))]
names(counties)[names(counties) == "GEOID"] <- "fips"
counties <- st_make_valid(counties)
save(counties, file = "data/counties.rda", compress = "xz")
message(sprintf("counties: %d features, %.1f MB", nrow(counties),
                file.size("data/counties.rda") / 1e6))

st <- states(cb = TRUE, resolution = "500k", year = yr, progress_bar = FALSE)
states <- st_make_valid(st_transform(
  st[, intersect(c("GEOID", "STATEFP", "STUSPS", "NAME", "ALAND"), names(st))],
  4269))
names(states)[names(states) == "GEOID"] <- "state_fips"
save(states, file = "data/states.rda", compress = "xz")
message(sprintf("states: %d features, %.1f MB", nrow(states),
                file.size("data/states.rda") / 1e6))

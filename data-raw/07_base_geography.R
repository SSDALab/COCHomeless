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

suppressMessages({ library(tigris); library(sf); library(rmapshaper) })
options(tigris_use_cache = TRUE, tigris_class = "sf")
stopifnot(dir.exists("data"))

# CANONICAL COUNTY VINTAGE for the whole package. Every county key in
# COCHomeless (area, homeless*, county_pit*, county_coc*, tract_coc*) must be
# built against this frame. 2024 TIGER is the first vintage in the package that
# carries Connecticut's planning regions (09110-09190, which replaced the eight
# legacy counties 09001-09015), Alaska's Chugach / Copper River / Kusilvak
# (02063 / 02066 / 02158) and South Dakota's Oglala Lakota (46102). Mixing this
# frame with a 2010-vintage benchmark is what silently zeroed those counties.
yr <- as.integer(Sys.getenv("TIGER_YEAR", "2024"))

co <- counties(cb = TRUE, resolution = "500k", year = yr, progress_bar = FALSE)
counties <- st_transform(co, 4269)
# ALAND and AWATER are both retained: area.R uses ALAND + AWATER as the density
# denominator, matching the semantics of the original tract-summed `area`.
counties <- counties[, intersect(c("GEOID", "STATEFP", "COUNTYFP", "NAME",
                                   "NAMELSAD", "STUSPS", "STATE_NAME",
                                   "ALAND", "AWATER"),
                                 names(counties))]
names(counties)[names(counties) == "GEOID"] <- "fips"
# Topology-preserving simplification: the cartographic 500k boundaries carry far
# more vertices than this package needs, and the shipped objects have always been
# simplified. KEEP is the retained-vertex share; ms_simplify keeps shared county
# borders coincident (plain st_simplify would open slivers between neighbours,
# which would corrupt the county x CoC overlap areas in 05_county_estimates.R).
KEEP <- as.numeric(Sys.getenv("GEOM_KEEP", "0.13"))
counties <- ms_simplify(counties, keep = KEEP, keep_shapes = TRUE, explode = FALSE)
counties <- st_make_valid(counties)
save(counties, file = "data/counties.rda", compress = "xz")
message(sprintf("counties: %d features, %.1f MB", nrow(counties),
                file.size("data/counties.rda") / 1e6))

st <- states(cb = TRUE, resolution = "500k", year = yr, progress_bar = FALSE)
states <- st_transform(
  st[, intersect(c("GEOID", "STATEFP", "STUSPS", "NAME", "ALAND", "AWATER"), names(st))],
  4269)
states <- st_make_valid(ms_simplify(states, keep = KEEP, keep_shapes = TRUE,
                                    explode = FALSE))
names(states)[names(states) == "GEOID"] <- "state_fips"
save(states, file = "data/states.rda", compress = "xz")
message(sprintf("states: %d features, %.1f MB", nrow(states),
                file.size("data/states.rda") / 1e6))

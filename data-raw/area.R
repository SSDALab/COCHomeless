################################################################################
# area.R
#
# County area in square kilometres, keyed on the canonical county FIPS frame.
#
#   area  data.frame, fips + skm
#
# Computed from the official Census land + water areas (ALAND + AWATER) carried
# on the canonical `counties` frame. Land + water reproduces the semantics of
# the original tract-summed figures: coastal and Great Lakes census tracts
# extend over water, so the legacy `area` was water-inclusive (Keweenaw County
# MI at 15,452 km2 against 1,520 km2 of land). Keeping that denominator keeps
# the density weights in 05_county_estimates.R comparable with the published
# estimates of Almquist, Helwig and You (2020).
#
# Using the Census fields rather than st_area() on the polygons also makes the
# figures exact and independent of the simplification tolerance applied to the
# shipped geometry.
#
# This replaces the original script, which summed 2010-vintage census-tract
# polygons from retired `sp` datasets. That approach froze `area` on the 2010
# county vintage: it had no rows for Connecticut's planning regions, Alaska's
# Chugach / Copper River / Kusilvak, or South Dakota's Oglala Lakota, and still
# carried the retired 02270 / 46113 / 51515. Because 05_county_estimates.R
# divides population by `skm` to get the density weight, every one of those
# counties silently fell out of the apportionment and was written as 0.
# Deriving area from the county frame itself makes that impossible by
# construction.
#
# Run from the package root, after 07_base_geography.R.
################################################################################

suppressMessages({ library(sf) })
stopifnot(dir.exists("data"))

load("data/counties.rda")
stopifnot(all(c("ALAND", "AWATER") %in% names(counties)))

# One decimal place, matching the precision of the legacy series. A few
# territory islands are smaller than 0.05 km2 and would round to zero (making
# density infinite), so those keep four significant digits.
skm <- (counties$ALAND + counties$AWATER) / 1e6
skm <- ifelse(skm >= 1, round(skm, 1), signif(skm, 4))

area <- data.frame(fips = counties$fips, skm = skm, stringsAsFactors = FALSE)
area <- area[order(area$fips), ]
rownames(area) <- NULL

stopifnot(!any(is.na(area$skm)), all(area$skm > 0),
          !anyDuplicated(area$fips),
          setequal(area$fips, counties$fips))

save(area, file = "data/area.rda", compress = "xz")
message(sprintf("area: %d counties, %.2f MB", nrow(area),
                file.size("data/area.rda") / 1e6))

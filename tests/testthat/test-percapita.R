# Year-by-year sanity checks on the county homeless estimates: nothing crazy.
# Catches systematic errors (e.g. a CoC misallocated to the wrong county) while
# tolerating a handful of inherently noisy very-small counties.

test_that("county counts are non-negative and never exceed population", {
  homeless <- get_dataset("homeless")
  cc <- grep("^count[0-9]+$", names(homeless), value = TRUE)
  for (y in cc) {
    v <- homeless[[y]]
    expect_true(all(v >= 0, na.rm = TRUE), info = paste(y, "has negative counts"))
    # logical bound: cannot have more homeless than residents
    over <- !is.na(homeless$population) & !is.na(v) & v > homeless$population
    expect_false(any(over),
                 info = paste(y, "count exceeds population in",
                              sum(over), "counties"))
  }
})

# Hard plausibility bound (metro-aware): no county estimate may exceed its cap
# in any year -- 3,500 per 100,000 for the dense major-metro cores (NYC boroughs
# and LA County), 2,000 per 100,000 elsewhere. Enforced by the water-fill +
# clip in 05_county_estimates.R.
PC_CAP   <- 2000
PC_METRO <- 3500
METRO_FIPS <- c("36061", "36047", "36081", "36005", "36085", "06037")

test_that("no county exceeds its per-capita cap in any year", {
  homeless <- get_dataset("homeless")
  cc <- grep("^count[0-9]+$", names(homeless), value = TRUE)
  cap <- ifelse(homeless$fips %in% METRO_FIPS, PC_METRO, PC_CAP)
  for (y in cc) {
    rate <- homeless[[y]] / homeless$population * 1e5
    bad <- which(!is.na(rate) & rate > cap + 1e-6)
    expect_length(bad, 0)
    if (length(bad))
      message(y, " over cap: ",
              paste(homeless$fips[bad], round(rate[bad]), collapse = "; "))
  }
})

test_that("no CoC exceeds 2,000 per 100,000 (per-capita on its counties)", {
  skip_on_cran()
  skip_if_not_installed("sf")
  sf::sf_use_s2(FALSE)
  sp_homeless <- get_dataset("sp_homeless")
  cpt <- suppressWarnings(sf::st_centroid(sp_homeless[, c("fips", "population")]))
  for (yr in c(2010L, 2017L, 2024L)) {        # representative years
    coc <- get_dataset(sprintf("coc%d", yr))
    hud <- get_dataset(sprintf("hud%d", yr))
    j <- suppressWarnings(sf::st_join(cpt, coc[, "COCNUM"], left = FALSE))
    pp <- aggregate(population ~ COCNUM, sf::st_drop_geometry(j), sum)
    m <- merge(hud, pp, by.x = "coc_num", by.y = "COCNUM")
    rate <- m$count / m$population * 1e5
    expect_true(all(rate <= PC_CAP, na.rm = TRUE),
                info = sprintf("%d: max CoC rate %.0f (%s)", yr,
                               max(rate, na.rm = TRUE),
                               m$coc_num[which.max(rate)]))
  }
})

test_that("national county totals are in a plausible band each year", {
  homeless <- get_dataset("homeless")
  cc <- grep("^count[0-9]+$", names(homeless), value = TRUE)
  for (y in cc) {
    tot <- sum(homeless[[y]], na.rm = TRUE)
    expect_true(tot > 3e5 && tot < 9.5e5,
                info = sprintf("%s national total = %s", y, format(tot)))
  }
})

test_that("imputed (homeless) and observed (homeless_na) agree where observed", {
  homeless    <- get_dataset("homeless")
  homeless_na <- get_dataset("homeless_na")
  cc <- grep("^count[0-9]+$", names(homeless), value = TRUE)
  for (y in cc) {
    obs <- !is.na(homeless_na[[y]])
    # capping aside, observed counties should match between the two tables
    expect_true(mean(homeless[[y]][obs] == homeless_na[[y]][obs]) > 0.99,
                info = paste(y, "imputed table changed observed counties"))
  }
})

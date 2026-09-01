# Validation against HUD's officially published figures.
#
# The package is built from HUD's "PIT Counts by CoC" workbook. HUD separately
# publishes "PIT Counts by State", which is an INDEPENDENT tabulation of the same
# count. Checking one against the other is the strongest external check available
# without a network call: a CoC silently dropped on import (as Kansas City was,
# in every year, because HUD writes its code as "MO-604a") shows up immediately
# as a national and state shortfall.
#
# fixtures/hud_pit_by_state.csv is that published state series, extracted
# verbatim by data-raw/pit_state_extract.py.

hud_state <- function() {
  utils::read.csv(test_path("fixtures", "hud_pit_by_state.csv"),
                  colClasses = c(state = "character", year = "integer",
                                 total = "integer"))
}

# STATEFP -> USPS, from the canonical county frame.
usps_of <- function() {
  d <- sf::st_drop_geometry(counties)
  stats::setNames(d$STUSPS, d$STATEFP)
}

# HUD reports MO-604 (Kansas City) as one combined row coded to Missouri in the
# by-CoC workbook, and as two separate portions in the by-State workbook, because
# the CoC covers territory in both Missouri and Kansas. Any CoC-keyed roll-up
# therefore differs from the by-State series for exactly these two states.
BISTATE <- c("KS", "MO")

test_that("national roll-up matches HUD's published national total", {
  h <- hud_state()
  nat <- tapply(h$total, h$year, sum)
  for (yr in years_for("hud")) {
    expect_equal(sum(get_dataset(sprintf("hud%d", yr))$count),
                 unname(nat[as.character(yr)]),
                 label = sprintf("sum(hud%d) vs HUD by-state roll-up", yr))
    expect_equal(pit_us$total[pit_us$year == yr], unname(nat[as.character(yr)]),
                 label = sprintf("pit_us vs HUD by-state roll-up, %d", yr))
  }
})

test_that("CoC-derived state totals match HUD exactly outside the bi-state CoC", {
  h <- hud_state()
  ours <- stats::aggregate(total ~ state + year,
                           data = transform(pit_coc,
                                            state = substr(coc_num, 1, 2)),
                           FUN = sum)
  cmp <- merge(h, ours, by = c("state", "year"), suffixes = c("_hud", "_ours"))
  cmp <- cmp[!(cmp$state %in% BISTATE), ]
  bad <- cmp[cmp$total_hud != cmp$total_ours, ]
  expect_equal(nrow(bad), 0,
               label = sprintf("state-years disagreeing with HUD (%s)",
                               paste(bad$state, bad$year, collapse = ", ")))
})

test_that("the bi-state CoC accounts for the whole Kansas/Missouri difference", {
  h <- hud_state()
  ours <- stats::aggregate(total ~ state + year,
                           data = transform(pit_coc,
                                            state = substr(coc_num, 1, 2)),
                           FUN = sum)
  cmp <- merge(h, ours, by = c("state", "year"))
  cmp <- cmp[cmp$state %in% BISTATE, ]
  cmp$resid <- cmp$total.x - cmp$total.y
  # Kansas is short by exactly what Missouri is over, every year.
  net <- tapply(cmp$resid, cmp$year, sum)
  expect_true(all(net == 0),
              label = "KS and MO residuals cancel in every year")
  expect_true(all(cmp$resid[cmp$state == "KS"] > 0))
})

test_that("county-derived state totals match HUD's published state totals", {
  # The county estimates are apportioned from CoC counts, so they should roll
  # back up to HUD's state figures. From 2011 on the median state matches
  # exactly. Earlier years run high because many CoCs held boundaries but filed
  # no PIT count, so their counties are filled by the imputation model rather
  # than by apportionment; that is the paper's method, not a defect.
  h <- hud_state()
  u <- usps_of()
  cty <- county_pit
  cty$state <- u[substr(cty$fips, 1, 2)]
  agg <- stats::aggregate(total ~ state + year, data = cty, FUN = sum)
  cmp <- merge(h, agg, by = c("state", "year"), suffixes = c("_hud", "_ours"))
  cmp$pct <- 100 * (cmp$total_ours - cmp$total_hud) / pmax(cmp$total_hud, 1)

  recent <- cmp[cmp$year >= 2017, ]
  expect_equal(median(abs(recent$pct)), 0,
               label = "median state deviation from HUD, 2017 onward")
  expect_lt(max(abs(recent$pct)), 12)
  expect_gt(mean(abs(recent$pct) < 5), 0.95)

  early <- cmp[cmp$year < 2017, ]
  expect_lt(max(abs(early$pct)), 50)
})

test_that("the bi-state split reaches the counties", {
  # Without HUD's published Missouri/Kansas split, density weighting hands dense
  # Wyandotte County KS a large share of the whole of MO-604 and pushes Kansas
  # about 29% above its officially reported total.
  h <- hud_state()
  u <- usps_of()
  cty <- county_pit
  cty$state <- u[substr(cty$fips, 1, 2)]
  agg <- stats::aggregate(total ~ state + year, data = cty, FUN = sum)
  cmp <- merge(h, agg, by = c("state", "year"), suffixes = c("_hud", "_ours"))
  # From 2019 on, where essentially every CoC reports a count, the two states
  # reproduce HUD's published totals exactly. 2016-2018 sit within 0.5%, and
  # before 2016 both states run high for the same reason every state does in
  # those years: counties of non-reporting CoCs are filled by the imputation
  # model, which is additive to the reported counts.
  recent <- cmp[cmp$state %in% BISTATE & cmp$year >= 2019, ]
  expect_equal(recent$total_ours, recent$total_hud,
               label = "KS and MO county totals equal HUD's published totals")

  mid <- cmp[cmp$state %in% BISTATE & cmp$year >= 2016, ]
  expect_lt(max(abs(mid$total_ours - mid$total_hud) / mid$total_hud), 0.005)
})

# ---- per capita -------------------------------------------------------------
# Rates are a numerator over a denominator, and only the numerator is ours. These
# tests hold the denominator fixed and check that our numerator reproduces the
# officially reported rate.

test_that("the national rate per 10,000 matches HUD's published figure", {
  # HUD, 2024 AHAR Part 1: 771,480 people, "about 23 of every 10,000 people in
  # the United States".
  pop <- sum(homeless$population)
  rate <- pit_us$total[pit_us$year == 2024] / pop * 1e4
  expect_equal(round(rate), 23)
  # Sanity across the series: the national rate has stayed in a narrow band.
  all_rates <- pit_us$total / pop * 1e4
  expect_true(all(all_rates > 10 & all_rates < 30))
})

test_that("state rates per 10,000 reproduce the official rates exactly", {
  h <- hud_state()
  h <- h[h$year == 2024, ]
  u <- usps_of()
  pop <- stats::aggregate(population ~ state, data = homeless, FUN = sum)
  pop$st <- u[pop$state]

  ours <- stats::aggregate(
    total ~ state,
    data = transform(pit_coc[pit_coc$year == 2024, ],
                     state = substr(coc_num, 1, 2)), FUN = sum)
  cmp <- merge(merge(h, ours, by = "state", suffixes = c("_hud", "_ours")),
               pop[, c("st", "population")], by.x = "state", by.y = "st")
  cmp$r_hud <- cmp$total_hud / cmp$population * 1e4
  cmp$r_ours <- cmp$total_ours / cmp$population * 1e4
  off <- cmp[!(cmp$state %in% BISTATE) & abs(cmp$r_ours - cmp$r_hud) > 1e-9, ]
  expect_equal(nrow(off), 0,
               label = sprintf("states whose rate differs from HUD's (%s)",
                               paste(off$state, collapse = ", ")))
  # No state rate should be implausible. DC is the highest at about 84/10,000.
  expect_lt(max(cmp$r_hud), 120)
  expect_gt(min(cmp$r_hud), 1)
})

test_that("county rates per 10,000 stay within the officially reported envelope", {
  # A county rate may legitimately exceed its state's rate -- homelessness
  # concentrates in urban cores -- but it is bounded by the apportionment cap,
  # and the population-weighted mean county rate must reproduce the state rate.
  h <- hud_state()
  h <- h[h$year == 2024, ]
  u <- usps_of()
  cp <- county_pit[county_pit$year == 2024, ]
  cp$state <- u[substr(cp$fips, 1, 2)]
  cp$population <- homeless$population[match(cp$fips, homeless$fips)]

  agg <- stats::aggregate(cbind(total, population) ~ state, data = cp, FUN = sum)
  cmp <- merge(h, agg, by = "state")
  cmp$r_ours <- cmp$total.y / cmp$population * 1e4
  cmp$r_hud <- cmp$total.x / cmp$population * 1e4
  expect_lt(max(abs(cmp$r_ours - cmp$r_hud)), 2,
            label = "state rate rebuilt from counties vs HUD's rate, per 10,000")

  rate <- cp$total / cp$population * 1e4
  expect_true(all(is.finite(rate)))
  expect_lte(max(rate), 350 + 1e-6,
             label = "county rate never exceeds the 3.5% metro cap")
})

test_that("crosswalk population roll-up is volume preserving", {
  # Rolling county population up to CoCs through county_coc<year>$w_county must
  # conserve the national population; if it does not, every per-capita rate
  # computed through the crosswalk is wrong.
  #
  # NOTE for users: w_county is an AREA share. For a dense sub-county CoC -- the
  # city CoCs such as MA-502 (Lynn) or MA-509 (Cambridge) -- area weighting badly
  # understates population and so inflates the per-capita rate. Use the
  # tract-level crosswalk (tract_coc<year>) with tract population for CoC rates.
  for (yr in c(2020L, 2024L, 2025L)) {
    cc <- get_dataset(sprintf("county_coc%d", yr))
    cc$population <- homeless$population[match(cc$fips, homeless$fips)]
    cc <- cc[!is.na(cc$population), ]
    rolled <- sum(cc$population * cc$w_county)
    expect_lt(abs(rolled / sum(homeless$population) - 1), 1e-6,
              label = sprintf("county_coc%d population roll-up conserves total", yr))
  }
})

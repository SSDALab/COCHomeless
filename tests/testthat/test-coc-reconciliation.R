# CoC-level reconciliation, in both directions.
#
# HUD marks CoC codes that carry a footnote with a trailing letter: Kansas City
# is written "MO-604a" because the CoC spans Missouri and Kansas. The extractors
# filtered on `^[A-Z]{2}-[0-9A-Za-z]{3}$`, so that row was silently discarded --
# from `hud*`, `pit_coc`, `pit_coc_detail` and `pit_us` alike, in all 19 years.
# Because `pit_us` sums the same filtered rows, the national totals were
# understated too and nothing disagreed with anything.
#
# The gate below is the fix for that: national totals are checked against HUD's
# published figures, so a dropped CoC fails the suite instead of shipping.

# HUD's published national PIT totals (AHAR Part 1, "PIT Estimates of
# Homelessness in the US"). Any CoC silently missing from the series shows up
# here as a shortfall.
HUD_NATIONAL <- c("2024" = 771480L, "2025" = 745652L)

test_that("national totals match HUD's published figures", {
  for (y in names(HUD_NATIONAL)) {
    expect_equal(pit_us$total[pit_us$year == as.integer(y)],
                 HUD_NATIONAL[[y]],
                 label = sprintf("pit_us total for %s", y))
  }
})

test_that("hud<year> sums to the national total for that year", {
  for (yr in years_for("hud")) {
    h <- get_dataset(sprintf("hud%d", yr))
    expect_equal(sum(h$count), pit_us$total[pit_us$year == yr],
                 label = sprintf("sum(hud%d) equals pit_us", yr))
  }
})

test_that("pit_coc totals reconcile with hud<year>", {
  for (yr in years_for("hud")) {
    h <- get_dataset(sprintf("hud%d", yr))
    p <- pit_coc[pit_coc$year == yr, ]
    expect_equal(sum(p$total), sum(h$count),
                 label = sprintf("pit_coc vs hud%d total", yr))
    expect_identical(sort(as.character(h$coc_num)), sort(p$coc_num),
                     label = sprintf("pit_coc vs hud%d CoC set", yr))
  }
})

test_that("Kansas City (MO-604) is present throughout the series", {
  # The footnote-marker regression test.
  for (yr in years_for("hud")) {
    h <- get_dataset(sprintf("hud%d", yr))
    expect_true("MO-604" %in% as.character(h$coc_num),
                label = sprintf("hud%d contains MO-604", yr))
    expect_gt(h$count[as.character(h$coc_num) == "MO-604"], 0)
  }
  expect_true(all(2007:2025 %in% pit_coc$year[pit_coc$coc_num == "MO-604"]))
  expect_true("MO-604" %in% as.character(pit_coc_detail$coc_num))
})

test_that("no CoC code carries an unstripped footnote marker", {
  bad <- grep("^[A-Z]{2}-[0-9A-Za-z]{3}[a-z]$", unique(pit_coc$coc_num), value = TRUE)
  expect_identical(bad, character(0),
                   label = paste("footnote-marked codes:", paste(bad, collapse = ", ")))
})

test_that("boundary CoCs that report a count appear in the PIT series", {
  # A CoC can have boundaries without reporting a PIT count -- common in the
  # early years, when many CoCs had geography but no count. The failure we care
  # about is the reverse: a CoC reporting a count that never reaches `hud*`.
  # That direction is covered by the national-total gate above; here we assert
  # the gap is shrinking rather than systematic.
  for (yr in c(2022L, 2023L, 2024L, 2025L)) {
    bnd <- coc_ids(get_dataset(sprintf("coc%d", yr)))
    pit <- as.character(get_dataset(sprintf("hud%d", yr))$coc_num)
    # American Samoa and the Northern Mariana Islands hold CoC geography but do
    # not report PIT counts.
    unreported <- setdiff(bnd, c(pit, "AS-500", "MP-500"))
    expect_identical(unreported, character(0),
                     label = sprintf("coc%d boundaries with no PIT count (%s)",
                                     yr, paste(unreported, collapse = ", ")))
  }
})

test_that("PIT CoCs have boundaries in the recent years", {
  for (yr in c(2023L, 2024L, 2025L)) {
    bnd <- coc_ids(get_dataset(sprintf("coc%d", yr)))
    pit <- as.character(get_dataset(sprintf("hud%d", yr))$coc_num)
    expect_identical(setdiff(pit, bnd), character(0),
                     label = sprintf("hud%d CoCs missing boundaries", yr))
  }
})

test_that("CoC counts reach counties: the apportionment conserves the total", {
  # CoC -> county direction. The county panel should account for essentially all
  # of the national PIT; a systematic shortfall means CoCs are not reaching any
  # county (which is what Connecticut looked like).
  for (yr in 2015:2025) {
    cc <- sprintf("count%02d", yr %% 100)
    got <- sum(homeless[[cc]], na.rm = TRUE)
    want <- pit_us$total[pit_us$year == yr]
    expect_gt(got / want, 0.97)
    expect_lt(got / want, 1.03)
  }
})

test_that("every CoC with a positive count reaches at least one county", {
  # county -> CoC direction, via the crosswalk.
  for (yr in c(2020L, 2024L, 2025L)) {
    h <- get_dataset(sprintf("hud%d", yr))
    cc <- get_dataset(sprintf("county_coc%d", yr))
    bnd <- coc_ids(get_dataset(sprintf("coc%d", yr)))
    # Only CoCs that have boundaries can be placed on counties. HUD's 2020
    # shapefile is missing several CoCs that did report a count (AL-505 and five
    # Maryland CoCs); that is a gap in the published boundary file, not in the
    # crosswalk, and is covered by the boundary-coverage test above.
    reporting <- intersect(as.character(h$coc_num[h$count > 0]), bnd)
    missing <- setdiff(reporting, unique(cc$COCNUM))
    # Territory CoCs report PIT counts, but the crosswalk's county frame is the
    # 50 states plus DC, so their counties are not in it.
    missing <- setdiff(missing, c("GU-500", "VI-500", "AS-500", "MP-500"))
    expect_identical(missing, character(0),
                     label = sprintf("CoCs absent from county_coc%d (%s)",
                                     yr, paste(missing, collapse = ", ")))
  }
})

test_that("county_coc weights normalize correctly", {
  for (yr in c(2007L, 2019L, 2020L, 2025L)) {
    cc <- get_dataset(sprintf("county_coc%d", yr))
    expect_false(any(is.na(cc$fips)),
                 label = sprintf("county_coc%d has no NA county keys", yr))
    w_coc <- tapply(cc$w_coc, cc$COCNUM, sum)
    expect_true(all(abs(w_coc - 1) < 1e-8),
                label = sprintf("county_coc%d w_coc sums to 1 per CoC", yr))
    w_county <- tapply(cc$w_county, cc$fips, sum)
    expect_true(all(abs(w_county - 1) < 1e-8),
                label = sprintf("county_coc%d w_county sums to 1 per county", yr))
  }
})

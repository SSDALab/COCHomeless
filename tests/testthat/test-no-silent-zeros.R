# A county that drops out of a join is written out as 0, not as an error. That
# is indistinguishable from a genuine zero unless something checks. These tests
# make the distinction structural rather than relying on a hand-maintained list
# of known-zero counties, which would rot.
#
# A county can legitimately be zero in every year: the apportionment splits each
# CoC's count by population density and rounds with a largest-remainder rule that
# preserves the CoC total, so a county whose raw share is a fraction of one
# person rounds to zero. Loving County TX has 96 residents and a raw 2024 share
# of 0.106. That is correct. What is NOT legitimate is a populous county reading
# zero, which is what a broken join looks like.

POP_FLOOR <- 50000   # CT's smallest planning region has 95,687 residents

count_cols <- function() grep("^count[0-9]{2}$", names(homeless), value = TRUE)

test_that("no populous county is zero in every year", {
  cc <- count_cols()
  totals <- rowSums(as.matrix(homeless[, cc]), na.rm = TRUE)
  offenders <- homeless$fips[totals == 0 & homeless$population > POP_FLOOR]
  expect_identical(
    sort(offenders), character(0),
    label = sprintf("counties over %d residents that are zero in all years (%s)",
                    POP_FLOOR, paste(offenders, collapse = ", "))
  )
})

test_that("every all-zero county is one the rounding legitimately floors", {
  cc <- count_cols()
  totals <- rowSums(as.matrix(homeless[, cc]), na.rm = TRUE)
  zeros <- homeless[totals == 0, ]
  # Tiny and sparse: a fraction of one person once the CoC total is split by
  # density. If a county here is large, the apportionment did not reach it.
  expect_true(all(zeros$population < POP_FLOOR),
              label = "all-zero counties are all small")
  expect_true(all(zeros$density < 10),
              label = "all-zero counties are all sparse")
})

test_that("every state has homeless counts in every year", {
  # The direct regression test for the Connecticut bug: CT CoC counts were
  # present, but all nine planning regions read 0 in all 19 years.
  cc <- count_cols()
  st <- substr(county_pit$fips, 1, 2)
  agg <- tapply(county_pit$total, list(st, county_pit$year), sum, na.rm = TRUE)
  empty <- which(agg == 0, arr.ind = TRUE)
  expect_equal(nrow(empty), 0,
               label = sprintf("state-years with no homeless anywhere (%s)",
                               paste(rownames(agg)[empty[, 1]],
                                     colnames(agg)[empty[, 2]],
                                     sep = "/", collapse = ", ")))
})

test_that("Connecticut planning regions carry non-zero counts", {
  ct <- county_pit[substr(county_pit$fips, 1, 2) == "09", ]
  expect_equal(length(unique(ct$fips)), 9)
  by_year <- tapply(ct$total, ct$year, sum)
  expect_true(all(by_year > 0), label = "CT county total positive in every year")

  # From 2015 on every CT CoC reports, so the counties should reproduce the CoC
  # totals exactly -- the apportionment is volume-preserving.
  coc_tot <- tapply(pit_coc$total[grepl("^CT-", pit_coc$coc_num)],
                    pit_coc$year[grepl("^CT-", pit_coc$coc_num)], sum)
  yrs <- as.character(2015:2025)
  expect_equal(unname(by_year[yrs]), unname(coc_tot[yrs]))
})

test_that("county_pit and county_pit_detail cover the same counties", {
  expect_identical(sort(unique(county_pit$fips)),
                   sort(unique(as.character(county_pit_detail$fips))))
})

test_that("counties whose primary CoC lacks a detail profile are still present", {
  # Wyandotte County KS and Jackson County MO both sit in MO-604 (Kansas City).
  # An inner join on the CoC detail profile used to drop them outright.
  for (f in c("20209", "29095")) {
    expect_true(f %in% county_pit_detail$fips,
                label = sprintf("county_pit_detail contains %s", f))
  }
})

test_that("sheltered and unsheltered sum to the total", {
  expect_true(all(county_pit$sheltered + county_pit$unsheltered ==
                    county_pit$total))
  expect_true(all(county_pit$sheltered >= 0), label = "sheltered non-negative")
  expect_true(all(county_pit$unsheltered >= 0), label = "unsheltered non-negative")
})

# Range and plausibility checks. Silent-zero detection (test-no-silent-zeros.R)
# catches counts that vanish; this file catches counts that are present but
# absurd -- a county with more homeless residents than residents, a negative
# count, or volatility the apportionment invented rather than inherited.

count_cols <- function() grep("^count[0-9]{2}$", names(homeless), value = TRUE)
count_matrix <- function() as.matrix(homeless[, count_cols()])

# The per-county plausibility cap the apportionment enforces: 3.5% of population
# for the dense major-metro cores, 2% everywhere else.
METRO_FIPS <- c("36061", "36047", "36081", "36005", "36085", "06037")
cap_rate <- function(fips) ifelse(fips %in% METRO_FIPS, 0.035, 0.02)

test_that("no count anywhere is negative or missing", {
  M <- count_matrix()
  expect_equal(sum(M < 0), 0, label = "negative county counts")
  expect_equal(sum(is.na(M)), 0, label = "missing county counts")

  for (nm in c("total", "sheltered", "unsheltered")) {
    expect_true(all(county_pit[[nm]] >= 0),
                label = sprintf("county_pit$%s non-negative", nm))
    expect_true(all(pit_coc[[nm]] >= 0, na.rm = TRUE),
                label = sprintf("pit_coc$%s non-negative", nm))
    expect_true(all(pit_us[[nm]] > 0), label = sprintf("pit_us$%s positive", nm))
  }
  expect_true(all(pit_coc_detail$count >= 0, na.rm = TRUE))
  expect_true(all(county_pit_detail$count >= 0, na.rm = TRUE))
})

test_that("no county has more homeless residents than residents", {
  M <- count_matrix()
  over <- which(M > homeless$population, arr.ind = TRUE)
  expect_equal(nrow(over), 0,
               label = sprintf("county-years with count > population (%s)",
                               paste(homeless$fips[over[, 1]], collapse = ", ")))
})

test_that("no county exceeds its plausibility cap", {
  M <- count_matrix()
  cap <- cap_rate(homeless$fips) * homeless$population
  over <- which(M > cap + 1, arr.ind = TRUE)
  expect_equal(nrow(over), 0,
               label = sprintf("county-years above the cap (%s)",
                               paste(unique(homeless$fips[over[, 1]]), collapse = ", ")))
  # The cap should bind rarely. If it starts binding often, the density weights
  # are pushing counts into the wrong counties.
  at_cap <- M >= floor(cap) - 0.5 & M > 0
  expect_lt(mean(at_cap), 0.01)
})

test_that("shelter status decomposes the total exactly", {
  expect_true(all(county_pit$sheltered + county_pit$unsheltered == county_pit$total))
  expect_true(all(pit_coc$sheltered + pit_coc$unsheltered == pit_coc$total,
                  na.rm = TRUE))
  expect_true(all(pit_coc$sheltered <= pit_coc$total, na.rm = TRUE))
  expect_true(all(county_pit$sheltered <= county_pit$total))
})

test_that("CoC counts stay in a plausible range", {
  expect_true(all(pit_coc$total < 2e5, na.rm = TRUE),
              label = "no CoC exceeds 200,000 (NY-600 is the largest, ~140k)")
  # Every year should have a plausible number of reporting CoCs.
  n_coc <- table(pit_coc$year)
  expect_true(all(n_coc > 350 & n_coc < 450),
              label = "CoCs reporting per year stays in 350-450")
})

test_that("county volatility is inherited from the CoCs, not manufactured", {
  # A county's count can jump a long way between years -- many California CoCs
  # more than quintupled from 2021 to 2022, because HUD waived the unsheltered
  # count in 2021. What must not happen is a county swinging when its CoC did
  # not. Compare the two distributions of year-over-year ratios: the county
  # panel should be no more volatile than the CoC panel it is derived from.
  M <- count_matrix()
  base <- M[, -ncol(M)]; nxt <- M[, -1]
  county_r <- (nxt / base)[base >= 50]

  pc <- pit_coc[order(pit_coc$coc_num, pit_coc$year), ]
  prev <- ave(pc$total, pc$coc_num, FUN = function(x) c(NA, utils::head(x, -1)))
  coc_r <- (pc$total / prev)[!is.na(prev) & prev >= 50]

  # No county may swing further than the widest swing any CoC made.
  expect_lte(max(county_r, na.rm = TRUE), max(coc_r, na.rm = TRUE) * 1.05)

  # Large moves must stay comparable in frequency to the CoC panel. The county
  # side runs somewhat hotter on the downside (about 1.5% of county-years versus
  # 0.9% of CoC-years): within a CoC the density split reallocates as well as
  # scales, and 41% of the large county drops are the single 2020-2021 step,
  # when HUD's waiver of the unsheltered count collapsed many CoC totals. Bound
  # it at twice the CoC rate, which leaves the known mechanism room while still
  # failing if the apportionment starts generating swings of its own.
  expect_lt(mean(county_r > 3, na.rm = TRUE),
            max(2 * mean(coc_r > 3, na.rm = TRUE), 0.002))
  expect_lt(mean(county_r < 1 / 3, na.rm = TRUE),
            max(2 * mean(coc_r < 1 / 3, na.rm = TRUE), 0.002))
})

test_that("national county totals track the published national totals", {
  for (yr in 2015:2025) {
    got <- sum(homeless[[sprintf("count%02d", yr %% 100)]])
    want <- pit_us$total[pit_us$year == yr]
    expect_lt(abs(got / want - 1), 0.03,
              label = sprintf("county total vs national PIT, %d", yr))
  }
})

test_that("detail subpopulations rarely exceed the overall total", {
  # HUD's own workbook carries a handful of these: some subpopulation categories
  # are counts of HOUSEHOLDS rather than people (MN-502 2007 reports 1,191
  # "Family Households" against 446 people), and a few CoC-years are internally
  # inconsistent at source. We assert the count stays negligible rather than
  # zero, so a systematic break in the apportionment still shows up.
  ov <- pit_coc_detail[pit_coc_detail$shelter == "Overall" &
                         pit_coc_detail$subpopulation == "All",
                       c("coc_num", "year", "count")]
  names(ov)[3] <- "tot"
  d <- pit_coc_detail[pit_coc_detail$shelter == "Overall" &
                        !is.na(pit_coc_detail$count), ]
  d <- merge(d, ov, by = c("coc_num", "year"))
  expect_lt(mean(d$count > d$tot, na.rm = TRUE), 1e-4)
})

test_that("ACS covariates are in range", {
  pct <- grep("^pct", names(homeless), value = TRUE)
  for (v in pct) {
    x <- homeless[[v]]
    expect_true(all(x >= 0 & x <= 100, na.rm = TRUE),
                label = sprintf("%s within 0-100", v))
  }
  expect_true(all(homeless$population > 0))
  expect_true(all(homeless$density > 0))
  expect_equal(sum(is.na(homeless$density)), 0)
})

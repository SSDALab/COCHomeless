# Allocation quality control: no reported person may be lost or misplaced on
# the way from a CoC's PIT count to the county estimates. Checks live in
# helper-qc.R; data-raw/13_qc_report.R writes the full flagged lists.

test_that("[BUG-008] every CoC with a boundary gap can borrow a polygon", {
  # HUD's yearly files omit some reporting CoCs. The build borrows the nearest
  # year's polygon; a CoC with none in ANY year could not be placed at all.
  miss <- qc_unplaced_cocs()
  never <- miss[is.na(miss$fallback_year), ]
  expect_identical(nrow(never), 0L,
                   label = sprintf("CoCs with no polygon in any year: %s",
                                   paste(unique(never$coc_num), collapse = ", ")))
  # and the build really used the fallback for every gap
  p <- get_dataset("county_coc_alloc")
  used <- unique(p[p$boundary_year != p$year, c("year", "coc_num")])
  gap <- unique(miss[, c("year", "coc_num")])
  placed <- paste(gap$coc_num, gap$year) %in% paste(used$coc_num, used$year)
  expect_true(all(placed),
              label = sprintf("boundary gaps not filled: %s",
                              paste(utils::head(paste(gap$coc_num, gap$year)[!placed], 10),
                                    collapse = ", ")))
})

test_that("[BUG-008] [BUG-010] the pre-imputation county panel conserves every year's PIT total", {
  # Checked on homeless_na, NOT the imputed homeless: imputation fills
  # uncovered counties with modelled people and can hide a leak entirely.
  # A few people of slack covers largest-remainder rounding at the caps.
  cons <- qc_conservation()
  bad <- cons[abs(cons$lost) > 10, ]
  expect_identical(
    nrow(bad), 0L,
    label = sprintf("years losing people between CoC and county: %s",
                    paste(sprintf("%d (%+d)", bad$year, bad$lost), collapse = ", ")))
})

test_that("[BUG-009] no county draws its count from a CoC that only slivers into it", {
  cov <- qc_primary_coverage()
  bad <- cov[cov$has_count & cov$share < QC_MIN_PRIMARY_SHARE, ]
  expect_identical(
    nrow(bad), 0L,
    label = sprintf("county-years apportioned from a <%g%% sliver, e.g. %s",
                    100 * QC_MIN_PRIMARY_SHARE,
                    paste(utils::head(sprintf("%s %d (%s, %.2f%%)", bad$fips,
                                              bad$year, bad$primary,
                                              100 * bad$share), 8),
                          collapse = "; ")))
})

test_that("[BUG-009] extreme county swings are explained by the CoC they come from", {
  # A county may swing because its CoC did (COVID 2021, a first unsheltered
  # count, ...), or because it was imputed. Swings with no such explanation
  # were manufactured by boundary handling and must not exist.
  sw <- qc_county_swings()
  bad <- sw[sw$cause == "unexplained", ]
  expect_identical(
    nrow(bad), 0L,
    label = sprintf("manufactured county swings, e.g. %s",
                    paste(utils::head(sprintf("%s %d: %d->%d", bad$fips, bad$year,
                                              bad$prev, bad$count), 8),
                          collapse = "; ")))
})

test_that("[BUG-008] [BUG-010] county_coc_alloc conserves every CoC's count exactly", {
  # Per-CoC (not just national) conservation: the people apportioned from each
  # CoC sum back to its HUD count in every year.
  al <- get_dataset("county_coc_alloc")
  placed <- tapply(al$count, paste(al$coc_num, al$year), sum)
  bad <- character()
  for (yr in QC_YEARS()) {
    h <- get_dataset(sprintf("hud%d", yr))
    h <- h[h$count > 0 & !qc_is_territory_coc(as.character(h$coc_num)), ]
    k <- paste(h$coc_num, yr)
    got <- placed[k]; got[is.na(got)] <- 0
    bad <- c(bad, sprintf("%s (%d/%d)", k[got != h$count], got[got != h$count],
                          h$count[got != h$count]))
  }
  expect_identical(bad, character(0))
})

test_that("[BUG-010] only Kansas City's CoC is split across states, onto Kansas", {
  al <- get_dataset("county_coc_alloc")
  bs <- al[al$role == "bi-state", ]
  expect_identical(unique(bs$coc_num), "MO-604")
  expect_true(all(substr(bs$fips, 1, 2) == "20"))
})

test_that("county_coc_alloc reconstructs every apportioned county estimate", {
  al <- get_dataset("county_coc_alloc"); hna <- get_dataset("homeless_na")
  for (yr in QC_YEARS()) {
    a <- al[al$year == yr, ]
    s <- tapply(a$count, a$fips, sum)
    v <- hna[[sprintf("count%02d", yr %% 100)]][match(names(s), hna$fips)]
    # the final per-capita clip can only lower a county below its sources
    expect_true(all(v <= s), label = sprintf("%d: county above its sources", yr))
    expect_gt(mean(v == s), 0.995)
    expect_true(all(is.na(hna[[sprintf("count%02d", yr %% 100)]][!hna$fips %in% names(s)])),
                label = sprintf("%d: county with a count but no source CoC", yr))
  }
})

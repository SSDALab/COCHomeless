# Census <-> CoC crosswalk: assignment uniqueness and weight normalization.

tol <- 1e-6

for (yr in years_for("tract_coc")) {
  test_that(sprintf("tract_coc%d is a clean one-CoC-per-tract assignment", yr), {
    d <- get_dataset(sprintf("tract_coc%d", yr))
    expect_true(all(c("GEOID", "fips", "COCNUM") %in% names(d)))
    expect_equal(anyDuplicated(d$GEOID), 0L)          # one row per tract
    expect_true(all(grepl("^[0-9]{11}$", d$GEOID)))
    expect_true(all(grepl("^[0-9]{5}$", d$fips)))
    expect_mostly_coc(d$COCNUM[!is.na(d$COCNUM)], label = sprintf("tract_coc%d", yr))
  })
}

for (yr in years_for("tract_coc_wt")) {
  test_that(sprintf("tract_coc_wt%d area weights sum to 1 per tract", yr), {
    d <- get_dataset(sprintf("tract_coc_wt%d", yr))
    s <- tapply(d$w_tract, d$GEOID, sum)
    expect_true(all(abs(s - 1) < 1e-4))
    expect_true(all(d$w_tract > 0 & d$w_tract <= 1 + tol))
  })
}

test_that("coc_mergers is a clean longitudinal CoC crosswalk", {
  skip_if_not("coc_mergers" %in% all_datasets(), "coc_mergers not built")
  d <- get_dataset("coc_mergers")
  expect_true(all(c("coc_pre", "coc_post", "merger_year") %in% names(d)))
  expect_mostly_coc(d$coc_pre, label = "coc_mergers$coc_pre")
  expect_mostly_coc(d$coc_post, label = "coc_mergers$coc_post")
  expect_true(all(d$coc_pre != d$coc_post))          # no self-merge
  expect_equal(anyDuplicated(d$coc_pre), 0L)         # each old code resolves once
  expect_true(is.numeric(d$merger_year))
  expect_true(all(d$merger_year >= 2000 & d$merger_year <= 2100))
})

for (yr in years_for("county_coc")) {
  test_that(sprintf("county_coc%d weights normalize in both directions", yr), {
    d <- get_dataset(sprintf("county_coc%d", yr))
    expect_true(all(c("fips", "COCNUM", "area_m2", "w_coc", "w_county") %in% names(d)))
    expect_true(all(d$area_m2 > 0))

    # w_coc apportions a CoC across its counties -> sums to 1 per CoC
    expect_true(all(abs(tapply(d$w_coc, d$COCNUM, sum) - 1) < 1e-4))
    # w_county aggregates a county across its CoCs -> sums to 1 per county
    expect_true(all(abs(tapply(d$w_county, d$fips, sum) - 1) < 1e-4))

    # every CoC in the crosswalk has a boundary that year, if available
    if (yr %in% years_for("coc")) {
      bnd <- coc_ids(get_dataset(sprintf("coc%d", yr)))
      expect_true(all(unique(d$COCNUM) %in% bnd))
    }
  })
}
